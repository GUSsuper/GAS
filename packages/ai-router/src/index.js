function createRouter(config = {}) {
  return {
    provider: config.provider || "openai",

    async chat(input) {
      return {
        provider: this.provider,
        status: "not_connected",
        input
      };
    }
  };
}

module.exports = { createRouter };
