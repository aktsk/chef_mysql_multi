name              "mysql_multi"
maintainer        "Akatsuki, Inc."
maintainer_email  "y.tanaka@aktsk.jp"
license           "MIT"
description       "Add multiple mysql instance"
long_description  "Add multiple mysql instance"
version           "0.0.1"

%w{redhat}.each do |os|
  supports os
end

depends 'mysql'
