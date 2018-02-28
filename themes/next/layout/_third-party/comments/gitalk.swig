{% if theme.gitalk.enable and page.comments %}
    <link rel='stylesheet' href="https://cdn.bootcss.com/gitalk/1.2.2/gitalk.min.css">
    <script src="https://cdn.bootcss.com/gitalk/1.2.2/gitalk.min.js"></script>
    <script type="text/javascript">
        var gitalk = new Gitalk({
          clientID:  '{{theme.gitalk.clientID}}', 
          clientSecret: '{{theme.gitalk.clientSecret}}',
          id: window.location.pathname,
          repo: '{{theme.gitalk.repo}}', 
          owner: '{{theme.gitalk.owner}}', 
          admin: ['{{theme.gitalk.admin}}'], 
          distractionFreeMode: '{{theme.gitalk.distractionFreeMode}}',
        })
        gitalk.render('gitalk-container')
    </script>
{% endif %}

