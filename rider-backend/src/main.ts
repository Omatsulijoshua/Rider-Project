import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ✅ Validation
  app.useGlobalPipes(new ValidationPipe());

  // ✅ Global prefix (VERY IMPORTANT)
  app.setGlobalPrefix('api');

  // ✅ FIX CORS (for Flutter Web)
  app.enableCors({
    origin: '*', // allow all (for development)
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  const port = Number(process.env.PORT ?? 3000);

  // ✅ VERY IMPORTANT (allow phone/browser access)
  await app.listen(port, '0.0.0.0');

  console.log(`🚀 Server running on: http://localhost:${port}`);
}

bootstrap();