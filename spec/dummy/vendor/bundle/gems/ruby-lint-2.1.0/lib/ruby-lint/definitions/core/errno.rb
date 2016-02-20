# This file was automatically generated, any manual changes will be lost the
# next time this file is generated.
#
# Platform: rbx 2.2.3.n364

RubyLint.registry.register('Errno') do |defs|
  defs.define_constant('Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('handle') do |method|
      method.define_optional_argument('additional')
    end
  end

  defs.define_constant('Errno::E2BIG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::E2BIG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::E2BIG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EACCES') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EACCES::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EACCES::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EADDRINUSE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EADDRINUSE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EADDRINUSE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EADDRNOTAVAIL') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EADDRNOTAVAIL::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EADDRNOTAVAIL::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EADV') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EADV::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EADV::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EAFNOSUPPORT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EAFNOSUPPORT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EAFNOSUPPORT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EAGAIN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EAGAIN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EAGAIN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EALREADY') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EALREADY::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EALREADY::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADF') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADF::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADF::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADFD') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADFD::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADFD::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADMSG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADMSG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADMSG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADR') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADR::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADR::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADRQC') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADRQC::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADRQC::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADSLT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADSLT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBADSLT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBFONT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBFONT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBFONT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBUSY') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EBUSY::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EBUSY::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECANCELED') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ECANCELED::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECANCELED::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECHILD') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ECHILD::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECHILD::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECHRNG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ECHRNG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECHRNG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECOMM') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ECOMM::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECOMM::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNABORTED') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNABORTED::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNABORTED::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNREFUSED') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNREFUSED::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNREFUSED::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNRESET') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNRESET::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ECONNRESET::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDEADLK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EDEADLK::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDEADLK::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDEADLOCK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EDESTADDRREQ') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EDESTADDRREQ::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDESTADDRREQ::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDOTDOT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EDOTDOT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDOTDOT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDQUOT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EDQUOT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EDQUOT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EEXIST') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EEXIST::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EEXIST::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EFAULT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EFAULT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EFAULT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EFBIG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EFBIG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EFBIG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EHOSTDOWN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EHOSTDOWN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EHOSTDOWN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EHOSTUNREACH') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EHOSTUNREACH::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EHOSTUNREACH::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EIDRM') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EIDRM::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EIDRM::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EILSEQ') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EILSEQ::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EILSEQ::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EINPROGRESS') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EINPROGRESS::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EINPROGRESS::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EINTR') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EINTR::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EINTR::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EINVAL') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EINVAL::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EINVAL::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EIO') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EIO::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EIO::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EISCONN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EISCONN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EISCONN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EISDIR') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EISDIR::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EISDIR::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EISNAM') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EISNAM::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EISNAM::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYEXPIRED') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYEXPIRED::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYEXPIRED::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYREJECTED') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYREJECTED::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYREJECTED::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYREVOKED') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYREVOKED::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EKEYREVOKED::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL2HLT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EL2HLT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL2HLT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL2NSYNC') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EL2NSYNC::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL2NSYNC::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL3HLT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EL3HLT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL3HLT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL3RST') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EL3RST::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EL3RST::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBACC') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBACC::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBACC::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBBAD') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBBAD::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBBAD::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBEXEC') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBEXEC::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBEXEC::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBMAX') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBMAX::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBMAX::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBSCN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBSCN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELIBSCN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELNRNG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ELNRNG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELNRNG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELOOP') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ELOOP::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ELOOP::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMEDIUMTYPE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EMEDIUMTYPE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMEDIUMTYPE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMFILE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EMFILE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMFILE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMLINK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EMLINK::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMLINK::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMSGSIZE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EMSGSIZE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMSGSIZE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMULTIHOP') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EMULTIHOP::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EMULTIHOP::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENAMETOOLONG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENAMETOOLONG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENAMETOOLONG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENAVAIL') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENAVAIL::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENAVAIL::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETDOWN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETDOWN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETDOWN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETRESET') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETRESET::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETRESET::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETUNREACH') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETUNREACH::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENETUNREACH::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENFILE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENFILE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENFILE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOANO') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOANO::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOANO::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOBUFS') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOBUFS::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOBUFS::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOCSI') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOCSI::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOCSI::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENODATA') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENODATA::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENODATA::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENODEV') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENODEV::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENODEV::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOENT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOENT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOENT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOEXEC') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOEXEC::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOEXEC::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOKEY') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOKEY::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOKEY::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOLCK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOLCK::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOLCK::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOLINK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOLINK::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOLINK::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMEDIUM') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMEDIUM::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMEDIUM::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMEM') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMEM::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMEM::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMSG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMSG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOMSG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENONET') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENONET::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENONET::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOPKG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOPKG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOPKG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOPROTOOPT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOPROTOOPT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOPROTOOPT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSPC') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSPC::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSPC::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSR') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSR::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSR::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSTR') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSTR::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSTR::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSYS') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSYS::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOSYS::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTBLK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTBLK::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTBLK::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTCONN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTCONN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTCONN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTDIR') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTDIR::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTDIR::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTEMPTY') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTEMPTY::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTEMPTY::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTNAM') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTNAM::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTNAM::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTRECOVERABLE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTRECOVERABLE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTRECOVERABLE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTSOCK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTSOCK::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTSOCK::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTTY') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTTY::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTTY::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTUNIQ') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTUNIQ::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENOTUNIQ::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENXIO') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ENXIO::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ENXIO::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EOPNOTSUPP') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EOPNOTSUPP::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EOPNOTSUPP::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EOVERFLOW') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EOVERFLOW::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EOVERFLOW::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EOWNERDEAD') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EOWNERDEAD::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EOWNERDEAD::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPERM') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EPERM::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPERM::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPFNOSUPPORT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EPFNOSUPPORT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPFNOSUPPORT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPIPE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EPIPE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPIPE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTO') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTO::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTO::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTONOSUPPORT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTONOSUPPORT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTONOSUPPORT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTOTYPE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTOTYPE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EPROTOTYPE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ERANGE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ERANGE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ERANGE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMCHG') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMCHG::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMCHG::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMOTE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMOTE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMOTE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMOTEIO') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMOTEIO::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EREMOTEIO::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ERESTART') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ERESTART::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ERESTART::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ERFKILL') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ERFKILL::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ERFKILL::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EROFS') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EROFS::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EROFS::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESHUTDOWN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ESHUTDOWN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESHUTDOWN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESOCKTNOSUPPORT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ESOCKTNOSUPPORT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESOCKTNOSUPPORT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESPIPE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ESPIPE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESPIPE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESRCH') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ESRCH::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESRCH::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESRMNT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ESRMNT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESRMNT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESTALE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ESTALE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESTALE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESTRPIPE') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ESTRPIPE::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ESTRPIPE::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETIME') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ETIME::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETIME::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETIMEDOUT') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ETIMEDOUT::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETIMEDOUT::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETOOMANYREFS') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ETOOMANYREFS::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETOOMANYREFS::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETXTBSY') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::ETXTBSY::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::ETXTBSY::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EUCLEAN') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EUCLEAN::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EUCLEAN::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EUNATCH') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EUNATCH::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EUNATCH::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EUSERS') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EUSERS::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EUSERS::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EWOULDBLOCK') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EXDEV') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EXDEV::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EXDEV::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EXFULL') do |klass|
    klass.inherits(defs.constant_proxy('SystemCallError', RubyLint.registry))

  end

  defs.define_constant('Errno::EXFULL::Errno') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::EXFULL::Strerror') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end

  defs.define_constant('Errno::FFI') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

    klass.define_method('add_typedef') do |method|
      method.define_argument('current')
      method.define_argument('add')
    end

    klass.define_method('config') do |method|
      method.define_argument('name')
    end

    klass.define_method('config_hash') do |method|
      method.define_argument('name')
    end

    klass.define_method('errno')

    klass.define_method('find_type') do |method|
      method.define_argument('name')
    end

    klass.define_method('generate_function') do |method|
      method.define_argument('ptr')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('generate_trampoline') do |method|
      method.define_argument('obj')
      method.define_argument('name')
      method.define_argument('args')
      method.define_argument('ret')
    end

    klass.define_method('size_to_type') do |method|
      method.define_argument('size')
    end

    klass.define_method('type_size') do |method|
      method.define_argument('type')
    end
  end

  defs.define_constant('Errno::Mapping') do |klass|
    klass.inherits(defs.constant_proxy('Object', RubyLint.registry))

  end
end
