---
title: Unity3D斗地主游戏 | (3) 地主牌显示和出牌逻辑
tags:
  - C#
  - Unity 3D
  - Game Development
categories: 软件设计
date: 2017-06-03
---
![avatar](https://mysite.bj.bcebos.com/images/articles/d2148f10-2a34-4bd6-af3f-76f0dfb70d33.jpg)

### 摘要
Hi，之前有同学说要我把源码发出来，那我就把半成品源码的链接放在每篇文件的最后，有兴趣的话可以查阅参考，有问题可以跟我私信，也可以关注我的个人公众号，互相交流嘛。当然，代码也是在不断的持续改进中~
上期我们实现了叫地主功能，不过遗留了一个小功能：叫地主完成以后，要显示地主的3张牌，这期首先弥补这块的功能；
接着我们要进入开发出牌逻辑的开发阶段，好了，废话不多说，继续我们斗地主开发之旅~
<!-- more -->

### 地主牌的显示
我们在玩家界面的顶部中间位置，放置一个新的GameObject，命名为BidCards，用来记录3张地主牌的显示位置。
所以我们重构了CardManager中的发牌方法，在给地主发牌同时，生成地主牌的实例，放在BidCards相应位置：
```csharp
/// <summary>
/// 发牌堆上的牌（如果现在不是抢地主阶段，发普通牌，如果是，发地主牌）
/// </summary>
/// <returns></returns>
private IEnumerator DealHeapCards(bool ifForBid)
{
    //显示牌堆
    heapPos.gameObject.SetActive(true);
    playerHeapPos.ToList().ForEach(s => { s.gameObject.SetActive(true); });

    var cardNamesNeeded = ifForBid
        ? cardNames.Skip(cardNames.Length - 3).Take(3)  //如果是抢地主牌，取最后3张
        : cardNames.Take(cardNames.Length - 3);         //如果首次发牌

    //计算每张地主牌的位置
    int cardIndex = 0;
    var width = (bidCards.GetComponent<RectTransform>().sizeDelta.x - 20) / 3;
    var centerBidPos = Vector3.zero;
    var leftBidPos = centerBidPos - Vector3.left * width;
    var rightBidPos = centerBidPos + Vector3.left * width;
    List<Vector3> bidPoss = new List<Vector3> { leftBidPos, centerBidPos, rightBidPos };
    foreach (var cardName in cardNamesNeeded)
    {
        //给当前玩家发一张牌
        Players[termCurrentIndex].AddCard(cardName);

        var cover = Instantiate(coverPrefab, heapPos.position, Quaternion.identity, heapPos.transform);
        cover.GetComponent<RectTransform>().localScale = Vector3.one;
        //移动动画，动画结束后自动销毁
        var tween = cover.transform.DOMove(playerHeapPos[termCurrentIndex].position, 0.3f);
        tween.OnComplete(() => Destroy(cover));

        yield return new WaitForSeconds(1 / dealCardSpeed);

        //如果给地主发牌
        if (ifForBid)
        {
            //显示地主牌
            var bidcard = Instantiate(cardPrefab, bidCards.transform.TransformPoint(bidPoss[cardIndex]), Quaternion.identity, bidCards.transform);
            bidcard.GetComponent<Card>().InitImage(new CardInfo(cardName));
            bidcard.GetComponent<RectTransform>().localScale = Vector3.one * 0.3f;
        }
        else
        {
            //下一个需要发牌者
            SetNextPlayer();
        }

        cardIndex++;
    }

    //隐藏牌堆
    heapPos.gameObject.SetActive(false);
    playerHeapPos[0].gameObject.SetActive(false);

    //发普通牌
    if (!ifForBid)
    {
        //显示玩家手牌
        ShowPlayerSelfCards();
        StartBiding();
    }
    //发地主牌
    else
    {
        if (Players[bankerIndex] is PlayerSelf)
        {
            //显示玩家手牌
            ShowPlayerSelfCards();
        }
        StartFollowing();
    }
}
```
好的，我们地主牌显示已经没有问题了，接下来，我们要实现出牌回合逻辑

### 出牌回合功能实现
出牌回合其实跟叫地主回合类似，也是可以抽象出3种方法：进入出牌阶段、出牌、不出（比较进入叫地主阶段、叫地主、不叫地主）；
因此，我们参照叫地主的逻辑，再实现出牌逻辑：

#### 调整Player基类
添加开始出牌ToFollowing、出牌ForFollow、不出NotFollow：
ToFollowing：进入自己回合，关闭其他人的倒计时，进入自己的倒计时阶段；
ForFollow：关闭自己的倒计时，然后将选择的牌添加到出牌区域，跳出自己回合；
NotFollow：关闭自己的倒计时，跳出自己回合；
```csharp
/// <summary>
/// 开始出牌
/// </summary>
public virtual void ToFollowing()
{
    isMyTerm = true;

    //关闭倒计时
    StopCountDown(CountDownTypes.Follow);

    //开始倒计时
    StartCountDown(CountDownTypes.Follow);
}
/// <summary>
/// 出牌
/// </summary>
public void ForFollow()
{
    //关闭倒计时
    StopCountDown(CountDownTypes.Follow);

    //选择的牌，添加到出牌区域
    var selectedCards = cardInfos.Where(s => s.isSelected).ToList();
    var offset = 5;
    for (int i = 0; i < selectedCards.Count(); i++)
    {
        var card = Instantiate(prefabSmall, smallCardPos.position + Vector3.right * offset * i, Quaternion.identity, smallCardPos.transform);
        card.GetComponent<RectTransform>().localScale = Vector3.one * 0.3f;
        card.GetComponent<Image>().sprite = Resources.Load("Images/Cards/" + selectedCards[i].cardName, typeof(Sprite)) as Sprite;
        card.transform.SetAsLastSibling();

        smallCards.Add(card);
    }
    cardInfos = cardInfos.Where(s => !s.isSelected).ToList();

    CardManager._instance.ForFollow();
    isMyTerm = false;
}
/// <summary>
/// 不出
/// </summary>
public void NotFollow()
{
    //关闭倒计时
    StopCountDown(CountDownTypes.Follow);

    CardManager._instance.NotFollow();
    isMyTerm = false;
}
/// <summary>
/// 销毁出牌对象
/// </summary>
public void DropAllSmallCards()
{
    smallCards.ForEach(Destroy);
    smallCards.Clear();
}
```

#### 调整PlayerSelf类
实现ToFollowing：
调用基类的ToFollowing，并显示出牌按钮以供玩家选择
```csharp
/// <summary>
/// 开始出牌
/// </summary>
public override void ToFollowing()
{
    base.ToFollowing();
    CardManager._instance.SetFollowButtonActive(true);
}
```

#### 调整PlayerOther类
模拟出牌，随机选择除手牌中的一张
```csharp
void Update()
{
    //如果当前是自己回合，模拟对手叫牌
    if (isMyTerm)
    {
        if (CardManager._instance.cardManagerState == CardManagerStates.Bid)
        {
            if (Input.GetKeyDown(KeyCode.Q))    //叫牌
            {
                ForBid();
            }
            if (Input.GetKeyDown(KeyCode.W))    //不叫
            {
                NotBid();
            }
        }
        if (CardManager._instance.cardManagerState == CardManagerStates.Playing)
        {
            if (Input.GetKeyDown(KeyCode.Q))    //出牌
            {
                var rd1 = Random.Range(0, cardInfos.Count);
                cardInfos[rd1].isSelected = true;

                ForFollow();
            }
            if (Input.GetKeyDown(KeyCode.W))    //不出
            {
                NotFollow();
            }
        }
    }
}
```

#### 调整CardManager
实现卡牌管理对玩家出牌的控制：
发完地主牌以后，开始出牌阶段，由地主先出牌；
玩家选择出牌后，将上轮玩家的出牌堆清空，并将选择的牌添加到自己的出牌堆，轮转到下个玩家；
玩家选择不出牌，将上轮玩家的出牌堆清空，轮转到下个玩家；
```csharp
/// <summary>
/// 开始出牌阶段
/// </summary>
private void StartFollowing()
{
    cardManagerState = CardManagerStates.Playing;
    //地主先出牌
    Players[bankerIndex].ToFollowing();
}
/// <summary>
/// 玩家出牌
/// </summary>
public void ForFollow()
{
    SetFollowButtonActive(false);

    //上轮玩家出牌清空
    Players[(termCurrentIndex + Players.Length - 1) % 3].DropAllSmallCards();
    if (Players[termCurrentIndex] is PlayerSelf)
        ShowPlayerSelfCards();

    SetNextPlayer();
    Players[termCurrentIndex].ToFollowing();
}
/// <summary>
/// 玩家不出
/// </summary>
public void NotFollow()
{
    SetFollowButtonActive(false);

    //上轮玩家出牌清空
    Players[(termCurrentIndex + Players.Length - 1) % 3].DropAllSmallCards();

    SetNextPlayer();
    Players[termCurrentIndex].ToFollowing();
}
```

### 代码整理
现在我们的代码具有一定的规模了，为了方便更好的管理，把现有的代码重新整理一下，并进行功能分类，比如：
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171106180001669-804442144.png) 
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171106180036888-107418205.png)     

### 总结
嗯，今天到此为止，我们再来测试验证下，当然，目前只是实现了出牌的功能，没有对牌力进行校验和出牌的控制，对手玩家随机模拟出牌，尚未加入AI。我们以后逐步去实现~来看看这期的效果吧~
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171106171732575-987926277.gif)   

### 资源
[项目源码](https://github.com/lizzie2008/ChinesePoker.git) 