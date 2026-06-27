import { Injectable } from '@nestjs/common';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { Readable } from 'stream';

@Injectable()
export class R2Service {
  private s3: S3Client;
  private bucketName = process.env.R2_BUCKET_NAME!;

  constructor() {
    this.s3 = new S3Client({
      region: 'auto', // R2 uses 'auto' as region
      endpoint: process.env.R2_ENDPOINT, // e.g., https://<account_id>.r2.cloudflarestorage.com
      credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY!,
        secretAccessKey: process.env.R2_SECRET_KEY!,
      },
    });
  }

  // Upload a file
  async uploadFile(key: string, buffer: Buffer, contentType: string) {
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: key, // e.g., 'kyc/user123.jpg'
      Body: buffer,
      ContentType: contentType,
    });

    return this.s3.send(command);
  }

  // Get a file as a stream
  async getFile(key: string): Promise<Readable> {
    const command = new GetObjectCommand({
      Bucket: this.bucketName,
      Key: key,
    });

    const response = await this.s3.send(command);
    return response.Body as Readable;
  }
}
