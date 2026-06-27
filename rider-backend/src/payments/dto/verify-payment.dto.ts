import { IsNotEmpty } from 'class-validator';

export class VerifyPaymentDto {
  @IsNotEmpty()
  transactionId!: string; // the ID returned by Flutterwave/Paystack

  @IsNotEmpty()
  paymentProvider!: 'flutterwave' | 'paystack';
}
