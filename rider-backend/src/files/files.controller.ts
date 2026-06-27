import { Controller, Post, Get, Param, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { R2Service } from './r2.service';

@Controller('files')
export class FilesController {
  constructor(private readonly r2Service: R2Service) {}
  
  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  async uploadFile(@UploadedFile() file: any) {
    const key = `orders/${Date.now()}-${file.originalname}`;
    await this.r2Service.uploadFile(key, file.buffer, file.mimetype);
    return { message: 'File uploaded', key };
  }

  @Get(':key(*)')
  async getFile(@Param('key') key: string, @Res() res: any) {
    const fileStream = await this.r2Service.getFile(key);
    fileStream.pipe(res);
  }
}
