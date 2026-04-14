import { IsString, IsNotEmpty, Matches, IsIn } from 'class-validator';

export class PresignUploadDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[a-zA-Z0-9_\-\.]{1,100}$/, {
    message: 'fileName must be 1-100 characters, alphanumeric/underscore/hyphen/dot only',
  })
  fileName: string;

  @IsString()
  @IsIn(['image/jpeg', 'image/png', 'image/heic', 'image/webp'], {
    message: 'contentType must be one of: image/jpeg, image/png, image/heic, image/webp',
  })
  contentType: string;
}
