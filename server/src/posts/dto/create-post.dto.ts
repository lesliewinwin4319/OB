import { IsString, IsNotEmpty, Matches } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @IsNotEmpty()
  subjectUid: string;

  @Matches(/^https:\/\/pub-9b13cc2e33104018a9cce774320589e2\.r2\.dev\/.+$/, {
    message: 'imageUrl must be a valid R2 public URL',
  })
  @IsNotEmpty()
  imageUrl: string;
}
