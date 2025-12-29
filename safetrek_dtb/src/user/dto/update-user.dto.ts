import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';

export class UpdateProfileDto {
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class ChangePinDto {
  @IsOptional()
  @IsString()
  oldPin?: string; // Mã PIN cũ (có thể không cần nếu chưa cài bao giờ)

  @IsString()
  @Length(4, 4, { message: 'Mã PIN an toàn phải có 4 ký tự' })
  safePin: string;

  @IsString()
  @Length(4, 4, { message: 'Mã PIN khẩn cấp phải có 4 ký tự' })
  duressPin: string;
}
