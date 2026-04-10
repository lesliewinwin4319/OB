import { Module, Global } from '@nestjs/common';
import * as dotenv from 'dotenv';

// 加载 .env 文件（Railway 直接注入环境变量时此步骤无副作用）
dotenv.config();

@Global()
@Module({})
export class ConfigModule {}
