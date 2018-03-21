{% if theme.baidushare.type === "button" %}
  <div class="bdsharebuttonbox">
    <a href="#" class="bds_mshare" data-cmd="mshare" title="分享到一键分享"></a>
    <a href="#" class="bds_weixin" data-cmd="weixin" title="分享到微信"></a>
    <a href="#" class="bds_sqq" data-cmd="sqq" title="分享到QQ好友"></a>
    <a href="#" class="bds_tsina" data-cmd="tsina" title="分享到新浪微博"></a>
    <a href="#" class="bds_tqq" data-cmd="tqq" title="分享到腾讯微博"></a>
    <a href="#" class="bds_youdao" data-cmd="youdao" title="分享到有道云笔记"></a>
    <a href="#" class="bds_evernotecn" data-cmd="evernotecn" title="分享到印象笔记"></a>
    <a href="#" class="bds_more" data-cmd="more"></a>
  </div>
  <br style="clear:both;" />
  <script>
    window._bd_share_config = {
      "common": {
        "bdText": "",
        "bdMini": "2",
        "bdMiniList": false,
        "bdPic": ""    
      },
      "share": {   
        "bdSize": "24",
        "bdStyle": "0"   
      }
    }
  </script>
{% elseif theme.baidushare.type === "slide" %}
  <script>
    window._bd_share_config = {
      "common": {
        "bdText": "",
        "bdMini": "1",
        "bdMiniList": false,
        "bdPic": ""
      },
      "image": {
        "viewList": ["tsina", "douban", "sqq", "qzone", "weixin", "twi", "fbook"],
        "viewText": "分享到：",
        "viewSize": "16"
      },
      "slide": {
        "bdImg": "5",
        "bdPos": "left",
        "bdTop": "100"
      }
    }
  </script>
{% endif %}
<script>
  with(document)0[(getElementsByTagName('head')[0]||body).appendChild(createElement('script')).src='//www.lancel0t.cn/static/api/js/share.js?cdnversion='+~(-new Date()/36e5)];
</script>
