# Copyright (C) 2007-2012 LuaDist.
# Created by Peter Drahoš, Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( lua-spore NONE )
cmake_minimum_required ( VERSION 2.8 )
include ( cmake/dist.cmake )
include ( lua )

install_lua_module ( Spore src/Spore.lua )
install_lua_module ( Spore.Core src/Spore/Core.lua )
install_lua_module ( Spore.GoogleDiscovery src/Spore/GoogleDiscovery.lua )
install_lua_module ( Spore.Middleware.Auth.AWS src/Spore/Middleware/Auth/AWS.lua )
install_lua_module ( Spore.Middleware.Auth.Basic src/Spore/Middleware/Auth/Basic.lua )
install_lua_module ( Spore.Middleware.Auth.Bearer src/Spore/Middleware/Auth/Bearer.lua )
install_lua_module ( Spore.Middleware.Auth.Digest src/Spore/Middleware/Auth/Digest.lua )
install_lua_module ( Spore.Middleware.Auth.Digest src/Spore/Middleware/Auth/DataPublica.lua )
install_lua_module ( Spore.Middleware.Auth.OAuth src/Spore/Middleware/Auth/OAuth.lua )
install_lua_module ( Spore.Middleware.Cache src/Spore/Middleware/Cache.lua )
install_lua_module ( Spore.Middleware.DoNotTrack src/Spore/Middleware/DoNotTrack.lua )
install_lua_module ( Spore.Middleware.Format.JSON src/Spore/Middleware/Format/JSON.lua )
install_lua_module ( Spore.Middleware.Format.XML src/Spore/Middleware/Format/XML.lua )
install_lua_module ( Spore.Middleware.Format.YAML src/Spore/Middleware/Format/YAML.lua )
install_lua_module ( Spore.Middleware.Logging src/Spore/Middleware/Logging.lua )
install_lua_module ( Spore.Middleware.Mock src/Spore/Middleware/Mock.lua )
install_lua_module ( Spore.Middleware.Parameter.Default src/Spore/Middleware/Parameter/Default.lua )
install_lua_module ( Spore.Middleware.Parameter.Force src/Spore/Middleware/Parameter/Force.lua )
install_lua_module ( Spore.Middleware.Proxy.Basic src/Spore/Middleware/Proxy/Basic.lua )
install_lua_module ( Spore.Middleware.Redirection src/Spore/Middleware/Redirection.lua )
install_lua_module ( Spore.Middleware.Runtime src/Spore/Middleware/Runtime.lua )
install_lua_module ( Spore.Middleware.UserAgent src/Spore/Middleware/UserAgent.lua )
install_lua_module ( Spore.Protocols src/Spore/Protocols.lua )
install_lua_module ( Spore.Request src/Spore/Request.lua )
install_lua_module ( Spore.XML src/Spore/XML.lua )
install_lua_module ( Spore.WADL src/Spore/WADL.lua )
install_lua_executable ( discovery2spore src/discovery2spore )
install_lua_executable ( wadl2spore src/wadl2spore )

install_data ( CHANGES COPYRIGHT README.md )
install_test ( test/ )
install_foo ( eg/ )
