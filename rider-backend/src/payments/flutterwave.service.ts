import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

// ✅ Define the interface at the top of the file
interface FlutterwaveVerifyResponse {
  status: string;
  data: {
    amount: number;
    customer: {
      email: string;
    };
    status: string;
  };
}

@Injectable()
export class FlutterwaveService {
  private readonly secret: string;

  constructor(private configService: ConfigService) {
    this.secret = this.configService.get<string>('FLW_SECRET_KEY')!;
  }

  // Initialize payment
  async initializePayment(email: string, amount: number) {
    const response = await axios.post(
      'https://api.flutterwave.com/v3/payments',
      {
        tx_ref: Date.now().toString(),
        amount,
        currency: 'NGN',
        customer: { email },
      },
      {
        headers: {
          Authorization: `Bearer ${this.secret}`,
          'Content-Type': 'application/json',
        },
      },
    );
    return response.data;
  }

  // Verify payment
  async verifyPayment(transactionId: string) {
    const response = await axios.get<FlutterwaveVerifyResponse>(
      `https://api.flutterwave.com/v3/transactions/${transactionId}/verify`,
      { headers: { Authorization: `Bearer ${this.secret}` } }
    );

    return {
      status: response.data.status,
      customerId: response.data.data.customer.email,
      amount: response.data.data.amount,
    };
  }
}
