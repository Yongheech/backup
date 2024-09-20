#!/bin/bash
# 미니콘다 설치
wget https://repo.anaconda.com/miniconda/Miniconda3-py310_24.7.1-0-Linux-x86_64.sh -O /tmp/Miniconda3.sh
bash /tmp/Miniconda3.sh -b -p /home/ubuntu/miniconda3
echo 'export PATH="/home/ubuntu/miniconda3/bin:$PATH"' >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc

# FastAPI / Uvicorn 설치
/home/ubuntu/miniconda3/bin/conda install -y python=3.10
/home/ubuntu/miniconda3/bin/pip install fastapi uvicorn sqlalchemy pymysql

# 간단한 FastAPI 앱 생성
cat <<EOL > /home/ubuntu/main.py
from fastapi import FastAPI
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

app = FastAPI()
engine = create_engine('mysql+pymysql://ubuntu:ubuntu@${mariadb_private_ip}:3306/ubuntu')
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@app.get('/')
def index():
    return {'Hello':'World!!'}

@app.get('/mariadb')
def mariadb():
    try:
        with SessionLocal() as conn:
            result = conn.execute(text('select sysdate();')).scalar()
            return {'msg': 'Database Connection successful!!',
                    'result': f'{result}'}
    except Exception as ex:
        return {'msg':'Database Connection failed!!', 'error':str(ex)}

EOL

# FastAPI 앱 실행
cat <<EOL > /etc/systemd/system/fastapi.service
[Unit]
Description=FastAPI app
After=network.target

[Service]
User=ubuntu
ExecStart=/home/ubuntu/miniconda3/bin/uvicorn main:app --host 0.0.0.0 --port 8000
WorkingDirectory=/home/ubuntu
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# FastAPI 자동 시작 지정
systemctl start fastapi
systemctl enable fastapi
