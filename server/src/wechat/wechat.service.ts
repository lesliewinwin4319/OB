import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import axios from 'axios';

export interface WechatSession {
  openId: string;
  unionId: string | null;
  sessionKey: string;
}

/**
 * 微信服务封装
 *
 * WECHAT_MOCK=true 时（开发/测试阶段）：
 *   - 任意非空 code 均视为有效
 *   - openId = mock_openid_{code}
 *   - unionId = null
 *
 * 生产阶段将 WECHAT_MOCK 设为 false，并填入真实 AppID/AppSecret。
 */
@Injectable()
export class WechatService {
  private readonly logger = new Logger(WechatService.name);
  private readonly isMock: boolean;
  private readonly appId: string;
  private readonly appSecret: string;

  constructor() {
    this.isMock = process.env.WECHAT_MOCK === 'true';
    this.appId = process.env.WECHAT_APP_ID || '';
    this.appSecret = process.env.WECHAT_APP_SECRET || '';
  }

  /**
   * 用微信登录码换取 openId 和 unionId
   * @param code 微信小程序 wx.login() 返回的临时码
   */
  async code2Session(code: string): Promise<WechatSession> {
    if (this.isMock) {
      this.logger.warn(`[MOCK] code2Session called with code: ${code}`);
      return {
        openId: `mock_openid_${code}`,
        unionId: null,
        sessionKey: 'mock_session_key',
      };
    }

    const url = 'https://api.weixin.qq.com/sns/jscode2session';
    const params = {
      appid: this.appId,
      secret: this.appSecret,
      js_code: code,
      grant_type: 'authorization_code',
    };

    try {
      const response = await axios.get(url, { params, timeout: 5000 });
      const data = response.data;

      if (data.errcode && data.errcode !== 0) {
        this.logger.error(`WeChat code2Session error: ${data.errcode} ${data.errmsg}`);
        throw new UnauthorizedException({
          errorCode: 'WECHAT_AUTH_FAILED',
          message: 'WeChat login failed, please try again',
        });
      }

      return {
        openId: data.openid,
        unionId: data.unionid || null,
        sessionKey: data.session_key,
      };
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      this.logger.error('WeChat API request failed', error);
      throw new UnauthorizedException({
        errorCode: 'WECHAT_API_ERROR',
        message: 'Unable to reach WeChat API',
      });
    }
  }
}
