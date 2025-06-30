#!/bin/bash
set -ex

# ==============================================================================
#  Phase 1: ROOT USER - System-level preparation
# ==============================================================================
echo ">>> Phase 1: Running system preparation as root..."

# --- Step 1.1: Define paths ---
SOURCE_DIR="/data/project/OpenTenBase"
INSTALL_DIR="/opt/opentenbase"
DATA_DIR="/data/nodes"

# --- Step 1.2: Create a PERMANENT environment setup for the opentenbase user ---
# This is THE MOST CRITICAL FIX. We create a .bashrc for the opentenbase user
# that unconditionally sources the environment variables. This ensures that ANY
# shell (interactive, or non-interactive via SSH) for this user gets the correct PATH.
ENV_SETUP_SCRIPT="/data/opentenbase/env.sh"
cat > "$ENV_SETUP_SCRIPT" << EOF
export OPENTENBASE_HOME=$INSTALL_DIR
export PATH=\$OPENTENBASE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$OPENTENBASE_HOME/lib:\$LD_LIBRARY_PATH
export LC_ALL=C
EOF

# Overwrite .bashrc to source our environment file at the very top.
echo "source $ENV_SETUP_SCRIPT" > /data/opentenbase/.bashrc

# --- Step 1.3: Create directories and set permissions ---
mkdir -p "$INSTALL_DIR"
chown -R opentenbase:opentenbase /data/opentenbase # This includes env.sh and .bashrc
chown -R opentenbase:opentenbase "$INSTALL_DIR"
chown -R opentenbase:opentenbase "$DATA_DIR"

# --- Step 1.4: Compile and install (if not already done) ---
if [ ! -f "$INSTALL_DIR/bin/postgres" ]; then
  echo ">>> Compiling source code..."
  cd "$SOURCE_DIR"
  chmod +x configure*
  ./configure --prefix="$INSTALL_DIR" --enable-user-switch --with-openssl --with-ossp-uuid CFLAGS="-g" LDFLAGS="-Wl,-rpath,'\$\$ORIGIN/../lib'"
  make -j$(nproc) && make install
  cd contrib && make -j$(nproc) && make install
fi

# --- Step 1.5: Start SSH service ---
service ssh start

# ==============================================================================
#  Phase 2: OPENTENBASE USER - Cluster setup and execution
# ==============================================================================
echo ">>> Phase 2: Switching to 'opentenbase' user for cluster operations..."

su - opentenbase -c "
  set -ex
  # We no longer need to source the env file here, .bashrc will handle it for all sub-processes.

  PGXC_CTL_HOME=\"/data/opentenbase/pgxc_ctl\"
  LOG_DIR=\"\${PGXC_CTL_HOME}/pgxc_log\"

  # Prepare pgxc_ctl config and SSH keys
  mkdir -p \"\$PGXC_CTL_HOME\"
  cp /data/project/OpenTenBase/pgxc_ctl.conf \"\$PGXC_CTL_HOME/\"

  mkdir -p ~/.ssh
  ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa -q
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  cat > ~/.ssh/config << EOC
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOC
  chmod 600 ~/.ssh/config

  # Initialize cluster if not already present
  if [ ! -d \"/data/nodes/gtm\" ]; then
      echo '>>> Initializing cluster as opentenbase user...'
      pgxc_ctl -c \"\${PGXC_CTL_HOME}/pgxc_ctl.conf\" init all
  fi

  echo '>>> Starting cluster as opentenbase user...'
  pgxc_ctl -c \"\${PGXC_CTL_HOME}/pgxc_ctl.conf\" start all

  # Wait a moment for the server to be ready for connections
  sleep 5

  # Add default node group and sharding group as per official docs
  echo '>>> Configuring default node and sharding groups...'
  # Be explicit with host and port for psql to avoid socket errors
  psql -h 127.0.0.1 -p 30004 -d postgres -U opentenbase -c 'CREATE DEFAULT NODE GROUP default_group WITH (dn1);'
  psql -h 127.0.0.1 -p 30004 -d postgres -U opentenbase -c 'CREATE SHARDING GROUP TO GROUP default_group;'
  
  echo -e \"\n#########################################################\"
  echo \"  OpenTenBase Cluster Dev Env is UP and RUNNING! \"
  echo \"  Connect via:\"
  echo \"  psql -h localhost -p 30004 -d postgres -U opentenbase\"
  echo \"#########################################################\n\"

  echo \">>> Tailing logs to keep container running...\"
  tail -f \${LOG_DIR}/*.log
"