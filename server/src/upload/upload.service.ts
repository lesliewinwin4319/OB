import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { PresignUploadDto } from './dto/presign-upload.dto';

@Injectable()
export class UploadService {
  private readonly s3: S3Client;
  private readonly bucketName: string;
  private readonly publicUrl: string;

  constructor() {
    this.bucketName = process.env.R2_BUCKET_NAME ?? '';
    this.publicUrl = (process.env.R2_PUBLIC_URL ?? '').replace(/\/$/, '');

    this.s3 = new S3Client({
      region: 'auto',
      endpoint: process.env.R2_S3_ENDPOINT,
      credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID ?? '',
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY ?? '',
      },
    });
  }

  async generatePresignedUrl(dto: PresignUploadDto): Promise<{
    uploadUrl: string;
    imageUrl: string;
    expiresIn: number;
  }> {
    const objectKey = `uploads/${crypto.randomUUID()}/${dto.fileName}`;

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: objectKey,
      ContentType: dto.contentType,
    });

    try {
      const uploadUrl = await getSignedUrl(this.s3, command, { expiresIn: 300 });
      const imageUrl = `${this.publicUrl}/${objectKey}`;
      return { uploadUrl, imageUrl, expiresIn: 300 };
    } catch (err) {
      throw new InternalServerErrorException('Failed to generate presigned URL');
    }
  }
}
