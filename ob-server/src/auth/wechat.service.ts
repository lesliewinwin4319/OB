import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

export interface WechatSessionResult {
  openid: string;
  unionid?: string;
}

/**
 * 微信登录服务
 *
 * 封装微信 App 登录（OAuth2 code 换 openid）的调用逻辑。
 * 注入 ConfigService 后可通过环境变量切换 mock/真实模式：
 * - WECHAT_APP_ID=wx_mock_appid 时自动进入 mock 模式（不发起真实网络请求）
 * - 正式环境替换真实 AppID 和 AppSecret 即可，无需改代码
 *
 * Mock 模式规则：
 * - code 非空即通过，直接返回 openid=mock_openid_{code}
 * - 后续接入真实微信 SDK 时，整体替换 mockCode2Session 方法即可
 */
@Injectable()
export class WechatService {
  private readonly logger = new Logger(WechatService.name);
  private readonly appId: string;
  private readonly appSecret: string;
  private readonly isMock: boolean;

  // 微信 App 登录接口（非小程序，使用 OAuth2 接口）
  private readonly WECHAT_TOKEN_URL =
    'https://api.weixin.qq.com/sns/oauth2/access_token';

  constructor(private readonly configService: ConfigService) {
    this.appId = this.configService.get<string>('WECHAT_APP_ID', '');
    this.appSecret = this.configService.get<string>('WECHAT_APP_SECRET', '');
    // AppID 包含 "mock" 时启用 mock 模式，方便本地开发和 CI 测试
    this.isMock = this.appId.includes('mock');

    if (this.isMock) {
      this.logger.warn(
        'WechatService is running in MOCK mode. ' +
          'Set real WECHAT_APP_ID and WECHAT_APP_SECRET for production.',
      );
    }
  }

  /**
   * 用微信授权 code 换取 openid（和可选的 unionid）
   *
   * @param code iOS 客户端从微信 SDK 拿到的一次性授权码
   */
  async code2Session(code: string): Promise<WechatSessionResult> {
    if (this.isMock) {
      return this.mockCode2Session(code);
    }

    try {
      const response = await axios.get<{
        access_token?: string;
        openid?: string;
        unionid?: string;
        errcode?: number;
        errmsg?: string;
      }>(this.WECHAT_TOKEN_URL, {
        params: {
          appid: this.appId,
          secret: this.appSecret,
          code,
          grant_type: 'authorization_code',
        },
        timeout: 5000,
      });

      const data = response.data;

      if (data.errcode || !data.openid) {
        this.logger.warn(
          `WeChat API error: errcode=${data.errcode}, errmsg=${data.errmsg}`,
        );
        throw new UnauthorizedException('微信授权失败，请重试');
      }

      return {
        openid: data.openid,
        unionid: data.unionid,
      };
    } catch (err) {
      if (err instanceof UnauthorizedException) throw err;
      this.logger.error('WeChat API request failed', err);
      throw new UnauthorizedException('微信服务暂时不可用，请稍后重试');
    }
  }

  private mockCode2Session(code: string): WechatSessionResult {
    // Mock 模式：code 非空即通过，不区分测试/生产环境
    // 接入真实微信 SDK 时，整体替换此方法即可，外层逻辑无需修改
    return {
      openid: `mock_openid_${code}`,
      unionid: `mock_unionid_${code}`,
    };
  }
}
