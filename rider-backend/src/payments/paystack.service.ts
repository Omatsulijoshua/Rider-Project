import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

// ✅ Type for Paystack verify response
interface PaystackVerifyResponse {
  status: boolean;
  message: string;
  data: {
    status: string;
    amount: number;
    customer: {
      email: string;
    };
  };
}
@Injectable()
export class PaystackService {
  private readonly secret: string;

  constructor(private configService: ConfigService) {
    this.secret = this.configService.get<string>('PAYSTACK_SECRET_KEY')!;
  }

  // Initialize payment
  async initializePayment(email: string, amount: number) {
    const response = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        email,
        amount: amount * 100, // Paystack expects kobo
      },
      {
        headers: {
          Authorization: `Bearer ${this.secret}`,
        },
      },
    );

    return response.data;
  }

  // Verify payment
  async verifyPayment(transactionId: string) {
    const response = await axios.get<PaystackVerifyResponse>(
      `https://api.paystack.co/transaction/verify/${transactionId}`,
      {
        headers: { Authorization: `Bearer ${this.secret}` },
      },
    );

    return {
      status: response.data.data.status,                  // string
      customerId: response.data.data.customer.email,      // string
      amount: response.data.data.amount / 100,           // convert to Naira
    };
  }
}
