FROM centos:centos7.3.1611

LABEL maintainer="Hiro Maru <hiro.maruhashi@nysol.co.jp>"

# 基本ライブラリ
RUN yum -y update; \
    yum -y groupinstall "Development Tools"; \
    yum -y install boost-devel libxml2-devel \
                   quota \
                   nano; \
    rm -rf /var/cache/yum/*; yum clean all;

# 言語を日本語に設定（必ずyum updateやyum reinstall glibcの後に実行)
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"
# 日付を日本語に設定
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock; \ 
    rm -f /etc/localtime; \
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime;

# Work Directories
WORKDIR /work
WORKDIR /github

# ruby
WORKDIR /github
RUN git clone https://github.com/sstephenson/rbenv.git
RUN echo 'export RBENV_ROOT="/github/rbenv"' >> ~/.bash_profile;\
    echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> ~/.bash_profile;\
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile;
ENV RBENV_ROOT /github/rbenv
ENV PATH /github/rbenv/bin:$PATH
RUN rbenv init -
RUN git clone git://github.com/sstephenson/ruby-build.git
WORKDIR ruby-build
RUN ./install.sh; \
    yum install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel; \
    rm -rf /var/cache/yum/*; yum clean all; \
    rbenv install 2.5.1; rbenv rehash; rbenv global 2.5.1;

# python
WORKDIR /github
RUN git clone https://github.com/pyenv/pyenv.git
RUN echo 'export PYENV_ROOT="/github/pyenv"' >> ~/.bash_profile;\
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile;\
    echo 'eval "$(pyenv init -)"' >> ~/.bash_profile;
ENV PYENV_ROOT /github/pyenv
ENV PATH /github/pyenv/bin:$PATH
RUN pyenv init -
RUN pyenv install 3.6.5; pyenv global 3.6.5;

# rbenv/pyenv関連パス設定
ENV PATH $RBENV_ROOT/shims:$RBENV_ROOT/plugins/ruby-build/bin:$PATH
ENV PATH $PYENV_ROOT/shims:$PATH

# mcmd
WORKDIR /github
RUN git clone https://github.com/nysol/mcmd.git; \
    cd mcmd; aclocal; autoreconf -i; ./configure; make; make install; \
    rm -rf /github/mcmd;

# mdmdex ( mbomsai, mkmeans, etc )
WORKDIR /github
RUN git clone https://github.com/nysol/mcmdex.git; \
    cd mcmdex; aclocal; autoreconf -i; ./configure; make; make install; \
    rm -rf /github/mcmdex.git;

# zdd
RUN gem install nysol-zdd

# take
RUN gem install nysol-take

# mining
RUN gem install nysol-mining
#  - gpmetis
RUN rpm -Uvh http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/m/metis-5.1.0-12.el7.x86_64.rpm

# mruby, meach, etc
RUN gem install nysol

# view
RUN gem install nysol-view

# fumi
RUN gem install nysol-fumi
#  - JUMAN
WORKDIR /work
RUN curl -O http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/juman/juman-7.01.tar.bz2; tar jxvf juman-7.01.tar.bz2;\
    cd juman-7.01; ./configure; make; make install; rm -rf /work/*;
#  - KNP
WORKDIR /work
RUN curl -O http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/knp/knp-4.19.tar.bz2; tar jxvf knp-4.19.tar.bz2;\
    cd knp-4.19; ./configure; make; make install; rm -rf /work/*;
#  - ENJU
WORKDIR /github
RUN git clone https://github.com/mynlp/enju.git; \
    cd enju; ./configure; make; make install; \
    rm -rf /github/enju;

# nysol_python
WORKDIR /github
RUN git clone https://github.com/nysol/nysol_python.git
WORKDIR nysol_python
RUN python setup.py build;
RUN python setup.py install;

# nysol_ruby
# RUN gem install nysol-ruby

### その他ライブラリ
# nkf
RUN yum -y install epel-release nkf; \
    rm -rf /var/cache/yum/*; yum clean all;
# graphviz
RUN yum -y install 'graphviz': \
    rm -rf /var/cache/yum/*; yum clean all;
# R
RUN yum -y install R; \
    rm -rf /var/cache/yum/*; yum clean all;
# 日本語フォント for matplotlib
ADD IPAfont00303.zip /usr/share/fonts
RUN unzip -d /usr/share/fonts /usr/share/fonts/IPAfont00303.zip

### application用
# python
RUN pip install --upgrade pip
RUN pip install flask
RUN pip install -U flask-cors
# ruby
RUN gem install thin
RUN gem install sinatra
RUN gem install sinatra-contrib
# node.js
RUN yum -y install nodejs; rm -rf /var/cache/yum/*; yum clean all;
# websocket for python
RUN pip install gevent-websocket

### 追加Rライブラリ
RUN R -e "install.packages('igraph', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('glmnet', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ROCR', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('tgp', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('arulesSequences', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('LPCM', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('LICORS', repos='http://cran.rstudio.com/')"
### 追加pythonライブラリ
RUN pip install jupyterhub
RUN npm install -g configurable-http-proxy
RUN pip install notebook
RUN pip install numpy
RUN pip install pandas -U
RUN pip install matplotlib bokeh plotly
RUN pip install scipy
RUN pip install scikit-learn
RUN pip install pip-review
RUN pip install python-Levenshtein
RUN pip install python-igraph
RUN pip install param
RUN pip install 'holoviews[recommended]'
RUN rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
RUN yum -y install mysql-community-client; rm -rf /var/cache/yum/*; yum clean all;
RUN pip install pymysql
RUN pip install ipython-sql
RUN pip install pyper
RUN pip install opencv-python
RUN pip install scikit-image
RUN pip install mglearn
RUN pip install pydot
RUN pip install keract
RUN pip install pydotplus

# ユーザー環境設定
WORKDIR /work
ENV LD_LIBRARY_PATH /usr/local/lib
