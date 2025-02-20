import 'express';
import { Multer } from 'multer';

declare global {
  namespace Express {
    interface Request {
      user: { 
        id: string; 
        profile: string; 
        isSuper: boolean;
        companyId: number;
      };
      companyId: number | undefined;
      tokenData: {
        id: string;
        username: string;
        profile: string;
        super: boolean;
        companyId: number;
        iat: number;
        exp: number;
      } | undefined;
      file?: Express.Multer.File;
      files?: Express.Multer.File[];
    }

    namespace Multer {
      interface File {
        fieldname: string;
        originalname: string;
        encoding: string;
        mimetype: string;
        size: number;
        destination: string;
        filename: string;
        path: string;
        buffer: Buffer;
      }
    }
  }
}
