const logger = {
  info: (msg) => console.log(`[INFO] ${msg}`),
  error: (msg) => console.error(`[ERROR] ${msg}`),
  debug: (msg) => {
    if (process.env.NODE_ENV === 'development') console.log(`[DEBUG] ${msg}`);
  }
};

module.exports = logger;