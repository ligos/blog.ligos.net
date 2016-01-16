cd hexo_root
call hexo generate
robocopy public \\loki\inetpub\sites\blog.ligos.net /mir /r:1 /w:1 
pause