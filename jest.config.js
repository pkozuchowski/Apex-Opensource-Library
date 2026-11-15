const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
    ...jestConfig,
    testPathIgnorePatterns: [...jestConfig.testPathIgnorePatterns, "<rootDir>/.claude/worktrees/"]
};
