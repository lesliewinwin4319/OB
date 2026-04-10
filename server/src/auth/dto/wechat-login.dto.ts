import { IsString, IsNotEmpty } from 'class-validator';

export class WechatLoginDto {
  @IsString()
  @IsNotEmpty({ message: 'code is required' })
  code: string;
}
