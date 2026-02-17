declare module 'busboy' {
  // Минимальные типы, чтобы next build проходил без @types/busboy на сервере.
  // Нам важна только возможность создать инстанс и подписаться на события.
  type BusboyOptions = {
    headers: Record<string, string> | Record<string, string | string[] | undefined>;
    limits?: Record<string, unknown>;
  };

  function Busboy(options: BusboyOptions): any;
  export default Busboy;
}

