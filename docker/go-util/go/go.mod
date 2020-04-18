module github.com/ForgeCloud/saas/tree/master/services/go

go 1.13

require (
	cloud.google.com/go v0.52.0
	cloud.google.com/go/datastore v1.0.0
	cloud.google.com/go/logging v1.0.0
	cloud.google.com/go/pubsub v1.0.1
	cloud.google.com/go/storage v1.4.0
	github.com/BurntSushi/toml v0.3.1
	github.com/LucasSloan/passwordbasedencryption v0.0.0-20190720234526-8bb15adf3263 // indirect
	github.com/Masterminds/goutils v1.1.0 // indirect
	github.com/Masterminds/semver v1.4.2 // indirect
	github.com/Masterminds/sprig v2.20.0+incompatible // indirect
	github.com/NickBall/go-aes-key-wrap v0.0.0-20170929221519-1c3aa3e4dfc5
	github.com/PuerkitoBio/goquery v1.5.0 // indirect
	github.com/appleboy/gofight v2.0.0+incompatible
	github.com/benburkert/openpgp v0.0.0-20160410205803-c2471f86866c // indirect
	github.com/buger/jsonparser v0.0.0-20181115193947-bf1c66bbce23
	github.com/bxcodec/faker v1.5.0
	github.com/cbroglie/mustache v1.0.1
	github.com/cyphar/filepath-securejoin v0.2.2 // indirect
	github.com/davecgh/go-spew v1.1.1
	github.com/dchest/uniuri v0.0.0-20160212164326-8902c56451e9
	github.com/dsnet/compress v0.0.1 // indirect
	github.com/dustin/go-humanize v1.0.0
	github.com/ericaro/frontmatter v0.0.0-20141225210444-9fedef9406e4
	github.com/evanphx/json-patch v4.5.0+incompatible // indirect
	github.com/frankban/quicktest v1.7.2 // indirect
	github.com/fsouza/fake-gcs-server v1.16.3
	github.com/ghodss/yaml v1.0.0 // indirect
	github.com/gin-contrib/sse v0.1.0 // indirect
	github.com/gin-gonic/gin v1.3.0
	github.com/go-mail/mail v2.3.1+incompatible
	github.com/go-test/deep v1.0.4
	github.com/gobwas/glob v0.2.3 // indirect
	github.com/gogo/protobuf v1.2.1 // indirect
	github.com/golang/protobuf v1.3.3
	github.com/golang/snappy v0.0.1 // indirect
	github.com/google/gofuzz v1.0.0 // indirect
	github.com/google/uuid v1.1.1
	github.com/googleapis/gnostic v0.3.0 // indirect
	github.com/gorilla/css v1.0.0 // indirect
	github.com/gregjones/httpcache v0.0.0-20190611155906-901d90724c79 // indirect
	github.com/hashicorp/go-multierror v1.0.0
	github.com/huandu/xstrings v1.2.0 // indirect
	github.com/imdario/mergo v0.3.8
	github.com/intel-go/fastjson v0.0.0-20170329170629-f846ae58a1ab
	github.com/jinzhu/copier v0.0.0-20190625015134-976e0346caa8
	github.com/labstack/echo v3.3.10+incompatible // indirect
	github.com/labstack/gommon v0.3.0 // indirect
	github.com/mholt/archiver v3.1.1+incompatible
	github.com/modern-go/reflect2 v0.0.0-20180701023420-4b7aa43c6742 // indirect
	github.com/namsral/flag v1.7.4-pre
	github.com/nwaples/rardecode v1.0.0 // indirect
	github.com/osamingo/jsonrpc v0.0.0-20191226055922-29994f892db1
	github.com/peterbourgon/diskv v2.0.1+incompatible // indirect
	github.com/pierrec/lz4 v2.4.0+incompatible // indirect
	github.com/pkg/errors v0.9.1
	github.com/russellcardullo/go-pingdom v1.0.0
	github.com/russross/blackfriday v2.0.0+incompatible
	github.com/sethgrid/pester v0.0.0-20180430140037-03e26c9abbbf
	github.com/shurcooL/sanitized_anchor_name v1.0.0 // indirect
	github.com/sirupsen/logrus v1.4.2
	github.com/storozhukBM/verifier v1.2.0
	github.com/stretchr/testify v1.4.0
	github.com/ugorji/go v1.1.7 // indirect
	github.com/vanng822/css v0.0.0-20190504095207-a21e860bcd04 // indirect
	github.com/vanng822/go-premailer v0.0.0-20191214114701-be27abe028fe
	github.com/xeipuuv/gojsonschema v1.2.0
	github.com/xi2/xz v0.0.0-20171230120015-48954b6210f8 // indirect
	golang.org/x/crypto v0.0.0-20191011191535-87dc89f01550
	golang.org/x/oauth2 v0.0.0-20200107190931-bf48bf16ab8d
	google.golang.org/api v0.17.0
	google.golang.org/genproto v0.0.0-20200210034751-acff78025515
	google.golang.org/grpc v1.27.1
	gopkg.in/alexcesaro/quotedprintable.v3 v3.0.0-20150716171945-2caba252f4dc // indirect
	gopkg.in/gin-gonic/gin.v1 v1.3.0 // indirect
	gopkg.in/go-playground/assert.v1 v1.2.1 // indirect
	gopkg.in/go-playground/validator.v8 v8.18.2
	gopkg.in/h2non/gock.v1 v1.0.15
	gopkg.in/inf.v0 v0.9.1 // indirect
	gopkg.in/mail.v2 v2.3.1 // indirect
	gopkg.in/src-d/go-billy.v4 v4.3.2
	gopkg.in/src-d/go-git.v4 v4.13.1
	gopkg.in/yaml.v2 v2.2.2
	k8s.io/api v0.0.0-20181204000039-89a74a8d264d
	k8s.io/apimachinery v0.0.0-20181127025237-2b1284ed4c93
	k8s.io/client-go v10.0.0+incompatible
	k8s.io/helm v2.13.1+incompatible
	k8s.io/klog v0.3.3 // indirect
	k8s.io/kube-openapi v0.0.0-20190709113604-33be087ad058 // indirect
	sigs.k8s.io/yaml v1.1.0 // indirect
)
