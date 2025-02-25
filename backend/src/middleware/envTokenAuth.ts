import { Request, Response, NextFunction } from "express";

const envTokenAuth = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  try {
    const { token: bodyToken } = req.body as { token?: string };
    const { token: queryToken } = req.query as { token?: string };

    if (queryToken === process.env.ENV_TOKEN || bodyToken === process.env.ENV_TOKEN) {
      return next();
    }

    res.status(403).json({ error: "Token inválido" });
  } catch (e) {
    console.error("Erro na autenticação:", e);
    res.status(500).json({ error: "Erro interno do servidor" });
  }
};

export default envTokenAuth;
