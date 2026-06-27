export class CreateKycDto {
  type!: 'CUSTOMER' | 'DRIVER';
  documents!: string[];
  selfie?: string; // optional for drivers
}
