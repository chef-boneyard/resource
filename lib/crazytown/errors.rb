module Crazytown
  class CrazytownError < StandardError
  end
  class CommitError < CrazytownError
  end
  class DoubleCommitError < CommitError
  end
end
