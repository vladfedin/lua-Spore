
LUA     := lua
VERSION := $(shell cd src && $(LUA) -e "m = require [[Spore]]; print(m._VERSION)")
TARBALL := lua-spore-$(VERSION).tar.gz
REV     := 1

LUAVER  := 5.1
PREFIX  := /usr/local
DPREFIX := $(DESTDIR)$(PREFIX)
BINDIR  := $(DPREFIX)/bin
LIBDIR  := $(DPREFIX)/share/lua/$(LUAVER)
INSTALL := install

all: dist.cmake
	@echo "Nothing to build here, you can just make install"

install:
	$(INSTALL) -m 755 -D src/discovery2spore                        $(BINDIR)/discovery2spore
	$(INSTALL) -m 644 -D src/Spore.lua                              $(LIBDIR)/Spore.lua
	$(INSTALL) -m 644 -D src/Spore/Core.lua                         $(LIBDIR)/Spore/Core.lua
	$(INSTALL) -m 644 -D src/Spore/GoogleDiscovery.lua              $(LIBDIR)/Spore/GoogleDiscovery.lua
	$(INSTALL) -m 644 -D src/Spore/Protocols.lua                    $(LIBDIR)/Spore/Protocols.lua
	$(INSTALL) -m 644 -D src/Spore/Request.lua                      $(LIBDIR)/Spore/Request.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Cache.lua             $(LIBDIR)/Spore/Middleware/Cache.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/DoNotTrack.lua        $(LIBDIR)/Spore/Middleware/DoNotTrack.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Logging.lua           $(LIBDIR)/Spore/Middleware/Logging.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Mock.lua              $(LIBDIR)/Spore/Middleware/Mock.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Redirection.lua       $(LIBDIR)/Spore/Middleware/Redirection.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Runtime.lua           $(LIBDIR)/Spore/Middleware/Runtime.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/UserAgent.lua         $(LIBDIR)/Spore/Middleware/UserAgent.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Auth/AWS.lua          $(LIBDIR)/Spore/Middleware/Auth/AWS.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Auth/Basic.lua        $(LIBDIR)/Spore/Middleware/Auth/Basic.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Auth/Bearer.lua       $(LIBDIR)/Spore/Middleware/Auth/Bearer.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Auth/DataPublica.lua  $(LIBDIR)/Spore/Middleware/Auth/DataPublica.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Auth/Digest.lua       $(LIBDIR)/Spore/Middleware/Auth/Digest.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Auth/OAuth.lua        $(LIBDIR)/Spore/Middleware/Auth/OAuth.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Format/JSON.lua       $(LIBDIR)/Spore/Middleware/Format/JSON.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Format/XML.lua        $(LIBDIR)/Spore/Middleware/Format/XML.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Format/YAML.lua       $(LIBDIR)/Spore/Middleware/Format/YAML.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Parameter/Default.lua $(LIBDIR)/Spore/Middleware/Parameter/Default.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Parameter/Force.lua   $(LIBDIR)/Spore/Middleware/Parameter/Force.lua
	$(INSTALL) -m 644 -D src/Spore/Middleware/Proxy/Basic.lua       $(LIBDIR)/Spore/Middleware/Proxy/Basic.lua

uninstall:
	rm -f $(LIBDIR)/Spore.lua
	rm -rf $(LIBDIR)/Spore

manifest_pl := \
use strict; \
use warnings; \
my @files = qw{MANIFEST}; \
while (<>) { \
    chomp; \
    next if m{^\.}; \
    next if m{^doc/\.}; \
    next if m{^doc/google}; \
    next if m{^rockspec/}; \
    push @files, $$_; \
} \
print join qq{\n}, sort @files;

rockspec_pl := \
use strict; \
use warnings; \
use Digest::MD5; \
open my $$FH, q{<}, q{$(TARBALL)} \
    or die qq{Cannot open $(TARBALL) ($$!)}; \
binmode $$FH; \
my %config = ( \
    version => q{$(VERSION)}, \
    rev     => q{$(REV)}, \
    md5     => Digest::MD5->new->addfile($$FH)->hexdigest(), \
); \
close $$FH; \
while (<>) { \
    s{@(\w+)@}{$$config{$$1}}g; \
    print; \
}

version:
	@echo $(VERSION)

CHANGES: dist.info
	perl -i.bak -pe "s{^$(VERSION).*}{q{$(VERSION)  }.localtime()}e" CHANGES

dist.info:
	perl -i.bak -pe "s{^version.*}{version = \"$(VERSION)\"}" dist.info

tag:
	git tag -a -m 'tag release $(VERSION)' $(VERSION)

doc:
	git read-tree --prefix=doc/ -u remotes/origin/gh-pages

MANIFEST: doc
	git ls-files | perl -e '$(manifest_pl)' > MANIFEST

$(TARBALL): MANIFEST
	[ -d lua-Spore-$(VERSION) ] || ln -s . lua-Spore-$(VERSION)
	perl -ne 'print qq{lua-Spore-$(VERSION)/$$_};' MANIFEST | \
	    tar -zc -T - -f $(TARBALL)
	rm lua-Spore-$(VERSION)
	rm -rf doc
	git rm doc/*

dist: $(TARBALL)

rockspec: $(TARBALL)
	perl -e '$(rockspec_pl)' rockspec.in > rockspec/lua-spore-$(VERSION)-$(REV).rockspec

install-rock: clean dist rockspec
	perl -pe 's{http://cloud.github.com/downloads/fperrad/lua-Spore/}{};' \
	    rockspec/lua-spore-$(VERSION)-$(REV).rockspec > lua-spore-$(VERSION)-$(REV).rockspec
	luarocks install lua-spore-$(VERSION)-$(REV).rockspec

check: test

export LUA_PATH=;;src/?.lua

test:
	prove --exec=$(LUA) ./test/*.t

test_eg:
	prove --exec=$(LUA) ./eg/*.lua

coverage:
	rm -f ./luacov.stats.out ./luacov.report.out
	-prove --exec="$(LUA) -lluacov" ./test/*.t
	luacov

README.html: README.md
	Markdown.pl README.md > README.html

clean:
	rm -rf doc
	rm -f MANIFEST *.bak src/luacov.*.out *.rockspec README.html

.PHONY: test rockspec CHANGES dist.info

