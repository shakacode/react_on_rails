# https://github.com/guard/listen/wiki/Duplicate-directory-errors
# Listen >=2.8 patch to silence duplicate directory errors. USE AT YOUR OWN RISK
require "listen/record/symlink_detector"
module Listen
  class Record
    class SymlinkDetector
      def _fail(_xxx, _yyy)
        raise Error, "Don't watch locally-symlinked directory twice"
      end
    end
  end
end
