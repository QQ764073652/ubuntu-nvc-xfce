# apps
os: ubuntu 16.04
vncserver port: 5901
no vnc port: 6901
vnc password: vncpassword
python3 
tensorflow 1.13.1
pycharm
chrome

# run
```bash
sudo docker run -itd -p 5901:5901 -p 6901:6901 registry.cn-beijing.aliyuncs.com/ruanxingbaozi/ubuntu-vnc-xfce-cu90:v1.2
```
# view
http://127.0.0.1:6901?password=vncpassword
