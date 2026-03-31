const parseLogging = (value) => {
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (normalized === "false") {
      return false;
    }

    if (normalized === "true") {
      return console.log;
    }
  }

  return value || false;
};

const buildConfig = (prefix) => ({
  username: process.env[`${prefix}_DB_USERNAME`],
  password: process.env[`${prefix}_DB_PASSWORD`],
  database: process.env[`${prefix}_DB_NAME`],
  host: process.env[`${prefix}_DB_HOSTNAME`],
  dialect: process.env[`${prefix}_DB_DIALECT`],
  logging: parseLogging(process.env[`${prefix}_DB_LOGGING`]),
});

/** @type {import('sequelize').Options} */
module.exports = {
  development: buildConfig("DEV"),
  test: buildConfig("TEST"),
  production: buildConfig("PROD"),
};
