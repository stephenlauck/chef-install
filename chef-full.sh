#!/bin/bash

if test "x$TMPDIR" = "x"; then
  tmp="/tmp"
else
  tmp=$TMPDIR
fi

# secure-ish temp dir creation without having mktemp available (DDoS-able but not exploitable)
tmp_dir="$tmp/install.sh.$$"
(umask 077 && mkdir $tmp_dir) || exit 1

exists() {
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
  fi
}

http_404_error() {
  echo "ERROR 404: Could not retrieve a valid install.sh!"
  exit 1
}

capture_tmp_stderr() {
  # spool up /tmp/stderr from all the commands we called
  if test -f "$tmp_dir/stderr"; then
    output=`cat $tmp_dir/stderr`
    stderr_results="${stderr_results}\nSTDERR from $1:\n\n$output\n"
    rm $tmp_dir/stderr
  fi
}

# do_wget URL FILENAME
do_wget() {
  echo "trying wget..."
  wget -O "$2" "$1" 2>$tmp_dir/stderr
  rc=$?
  # check for 404
  grep "ERROR 404" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "wget"
    return 1
  fi

  return 0
}

# do_curl URL FILENAME
do_curl() {
  echo "trying curl..."
  curl -sL -D $tmp_dir/stderr -o "$2" "$1" 2>$tmp_dir/stderr
  rc=$?
  # check for 404
  grep "404 Not Found" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "curl"
    return 1
  fi

  return 0
}

# do_fetch URL FILENAME
do_fetch() {
  echo "trying fetch..."
  fetch -o "$2" "$1" 2>$tmp_dir/stderr
  # check for bad return status
  test $? -ne 0 && return 1
  return 0
}

# do_perl URL FILENAME
do_perl() {
  echo "trying perl..."
  perl -e "use LWP::Simple; getprint(shift @ARGV);" "$1" > "$2" 2>$tmp_dir/stderr
  rc=$?
  # check for 404
  grep "404 Not Found" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "perl"
    return 1
  fi

  return 0
}

# do_python URL FILENAME
do_python() {
  echo "trying python..."
  python -c "import sys,urllib2 ; sys.stdout.write(urllib2.urlopen(sys.argv[1]).read())" "$1" > "$2" 2>$tmp_dir/stderr
  rc=$?
  # check for 404
  grep "HTTP Error 404" $tmp_dir/stderr 2>&1 >/dev/null
  if test $? -eq 0; then
    http_404_error
  fi

  # check for bad return status or empty output
  if test $rc -ne 0 || test ! -s "$2"; then
    capture_tmp_stderr "python"
    return 1
  fi
  return 0
}

# do_download URL FILENAME
do_download() {
  PATH=/opt/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sfw/bin:/sbin:/bin:/usr/sbin:/usr/bin
  export PATH

  echo "downloading $1"
  echo "  to file $2"

  # we try all of these until we get success.
  # perl, in particular may be present but LWP::Simple may not be installed

  if exists wget; then
    do_wget $1 $2 && return 0
  fi

  if exists curl; then
    do_curl $1 $2 && return 0
  fi

  if exists fetch; then
    do_fetch $1 $2 && return 0
  fi

  if exists perl; then
    do_perl $1 $2 && return 0
  fi

  if exists python; then
    do_python $1 $2 && return 0
  fi

  echo ">>>>>> wget, curl, fetch, perl, or python not found on this instance."

  if test "x$stderr_results" != "x"; then
    echo "\nDEBUG OUTPUT FOLLOWS:\n$stderr_results"
  fi

  return 16
}

  install_sh="https://www.opscode.com/chef/install.sh"
  if ! exists /usr/bin/chef-client; then
    echo "-----> Installing Chef Omnibus"
    do_download ${install_sh} $tmp_dir/install.sh
    sh $tmp_dir/install.sh -P chef
  else
    echo "-----> Existing Chef installation detected"
  fi

if test "x$tmp_dir" != "x"; then
  rm -r "$tmp_dir"
fi

mkdir -p /etc/chef

# <% if client_pem -%>
# cat > /etc/chef/client.pem <<EOP
# <%= ::File.read(::File.expand_path(client_pem)) %>
# EOP
# chmod 0600 /etc/chef/client.pem
# <% end -%>

# <% if validation_key -%>
# cat > /etc/chef/validation.pem <<EOP
# <%= validation_key %>
# EOP
# chmod 0600 /etc/chef/validation.pem
# <% end -%>

# <% if encrypted_data_bag_secret -%>
# cat > /etc/chef/encrypted_data_bag_secret <<EOP
# <%= encrypted_data_bag_secret %>
# EOP
# chmod 0600 /etc/chef/encrypted_data_bag_secret
# <% end -%>

mkdir -p /etc/chef/trusted_certs

mkdir -p /etc/chef/ohai/hints


# cat > /etc/chef/client.rb <<EOP
# <%= config_content %>
# EOP

# cat > /etc/chef/first-boot.json <<EOP
# <%= Chef::JSONCompat.to_json(first_boot) %>
# EOP

echo "Starting first Chef Client run..."

chef-client -j /etc/chef/first-boot.json