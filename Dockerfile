FROM amazonlinux:latest as intermediate

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | bash
RUN (yum install git git-lfs ssh -y) && git lfs install

ARG GITHUB_SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/
RUN echo "${GITHUB_SSH_PRIVATE_KEY}" >  /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan imaginelearning.com >> /root/.ssh/known_hosts

RUN ssh -o StrictHostKeyChecking=no -vT git@github.com 2>&1 | grep -i auth

RUN git clone -b master --single-branch git@github.com:rakesh-singh/test.git /srv/Torchevere-App
RUN rm -rf /srv/Torchevere-App/.git
RUN git clone -b third_gen --single-branch git@github.com:rakesh-singh/test.git /tmp/OpenNMT-py
RUN rm -rf /tmp/OpenNMT-py/.git
RUN rm -vf /root/.ssh/id*

FROM amazonlinux:latest
COPY --from=intermediate /srv/Torchevere-App /srv/Torchevere-App
COPY --from=intermediate /tmp/OpenNMT-py /tmp/OpenNMT-py

ENV PATH /opt/conda/bin:$PATH

RUN ((yum install bzip2 zip -y) && (curl https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh > /tmp/miniconda.sh) && (echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh) && (chmod u+x /tmp/miniconda.sh) && (bash /tmp/miniconda.sh -b -p /opt/conda)) 
RUN /bin/bash -c 'conda env create -f /srv/Torchevere-App/env/conda_env.yml; source activate torchevere-app; pip install --upgrade --no-cache-dir pip wheel; pip install --no-cache-dir -r /srv/Torchevere-App/env/requirements.txt; conda update numpy; conda install pytorch torchvision -c soumith; pip install --no-cache-dir -r /tmp/OpenNMT-py/requirements.txt; cd /tmp/OpenNMT-py/; pip install --no-cache-dir .; conda clean -t'


RUN ((rm /tmp/miniconda.sh) && (yum remove bzip2 zip git vim git-lfs -y) && (rm -rf /tmp/OpenNMT-py) && (chmod u+x /srv/Torchevere-App/torchevere_bot.py) && (yum clean all))

EXPOSE 8888

WORKDIR "/srv/Torchevere-App"
ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "source activate torchevere-app && python /srv/Torchevere-App/torchevere_bot.py -io flask" ]
