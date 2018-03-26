---
title: Unity3D斗地主游戏 | (2) 叫地主功能实现
tags:
  - C#
  - Unity 3D
  - Game Development
categories: 软件设计
date: 2017-06-02
---
![avatar](https://mysite.bj.bcebos.com/images/articles/9c93ff41-2251-428d-9a13-d553c20b6d65.jpg)

### 摘要
前面我们实现了点击开始游戏按钮，系统依次给玩家发牌的逻辑和动画，并展示当前的手牌。这期我们继续实现接下来的功能--叫地主。
<!-- more -->

### 大体思路
1.首先这两天，学习了DOTween，这是一个强大的Unity动画插件，大家可以参考：DOTween官方文档，个人感觉DOTween还是比较好用的。
好的，我们先来重构一下动画部分的代码（没有绝对牛逼的架构和设计，项目过程中不要不断的持续改进嘛）；先把之前ITween相关引用从项目中删除，然后导入DOTween插件。
相关动画代码改造示例如下：
```csharp
//移动动画，动画结束后自动销毁
var tween = cover.transform.DOMove(playerHeapPos[termCurrentIndex].position, 0.3f);
tween.OnComplete(() => Destroy(cover));
```
怎么样，比之前简洁多了吧，而且之前ITween好像不太好用，处理自动销毁时，跟协程点冲突（可能我自己用的方式不对），现在改用DOTween，一点问题也没有~官网上也有这几个动画插件的性能比较，相对来说DOTween表现还是很不错的。
2.再来说说具体的设计思路
刚开始觉得叫地主逻辑挺简单，不就是分2次发牌嘛，第一次发51张，后面谁叫到地主再发3张就好了嘛，但其实实现的过程中，发现没有那么简单，需要注意的细节挺多：
&emsp;a.发牌逻辑调整：因为发牌是按照当前玩家顺序，依次发牌，相当一个箭头一直指向当前回合玩家，发完51张牌后，箭头又开始指向开始发牌的玩家；这时候，需要判断首次发牌结束，由当前回合玩家开始叫牌；
&emsp;b.当前玩家进入叫牌阶段时，触发倒计时，倒计时内如果玩家选择叫牌，则箭头保持不变，然后开始继续给当前玩家发3张剩余的牌；
&emsp;c.倒计时内如果玩家选择不叫，则箭头继续指向下个玩家，下个玩家开始叫牌，回到分支b;
&emsp;d.倒计时内玩家如果没有任何选择，结束后默认不叫，回到分支c;
&emsp;e.如果3个玩家都没叫，则流局，重新开局（本期未实现，很容易，大家后面可以自己去尝试实现）；
&emsp;f.可以选择叫3分、2分、1分（将来需要实现，设计开发提前考虑）
&emsp;h.考虑到玩家自己和对手叫牌逻辑不一样，自己的话，通过界面点击触发，对手暂时监听按键触发（后期改智能AI判断），比如按下Q叫牌，按下W不叫；
&emsp;i.倒计时设计，叫牌的时候，需要显示玩家面前的计时器，计时结束后触发不叫，其他情况下隐藏；
&emsp;j.玩家只有自己回合才能叫地主，必须做限制；

### 玩家类调整
Player作为玩家的基类，我们需要增加ToBiding（开始叫地主），ForBid（抢地主），NotBid（不抢地主），来控制玩家在叫地主过程中的公共逻辑。
ToBiding：转到自己回合，并设置倒计时；
ForBid：跳出增加回合，停止倒计时，并调用卡牌管理类中的抢地主功能；
ForBid：跳出增加回合，停止倒计时，并调用卡牌管理类中的不抢地主功能；
然后，倒计时这块，添加一个协程Considerating，专门处理倒计时控件显示，标识玩家正在考虑中；
```csharp
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public abstract class Player : MonoBehaviour
{
    protected List<CardInfo> cardInfos = new List<CardInfo>();  //个人所持卡牌

    private Text cardCoutText;
    private Text countDownText;
    private int consideratingTime = 6; //玩家考虑时间
    protected bool isMyTerm = false;  //当前是否是自己回合

    void Start()
    {
        cardCoutText = transform.Find("HeapPos/Text").GetComponent<Text>();
        countDownText = transform.Find("CountDown/Text").GetComponent<Text>();
    }

    /// <summary>
    /// 增加一张卡牌
    /// </summary>
    /// <param name="cardName"></param>
    public void AddCard(string cardName)
    {
        cardInfos.Add(new CardInfo(cardName));
        cardCoutText.text = cardInfos.Count.ToString();
    }
    /// <summary>
    /// 清空所有卡片
    /// </summary>
    public void DropCards()
    {
        cardInfos.Clear();
    }

    /// <summary>
    /// 用户考虑时间
    /// </summary>
    private IEnumerator Considerating()
    {
        //倒计时
        var time = consideratingTime;
        while (time > 0)
        {
            countDownText.text = time.ToString();

            yield return new WaitForSeconds(1);
            time--;
        }
        NotBid();
    }
    /// <summary>
    /// 开始叫地主
    /// </summary>
    public virtual void ToBiding()
    {
        isMyTerm = true;

        //开始倒计时
        countDownText.transform.parent.gameObject.SetActive(true);
        StartCoroutine("Considerating");
    }
    /// <summary>
    /// 抢地主
    /// </summary>
    public void ForBid()
    {
        //关闭倒计时
        countDownText.transform.parent.gameObject.SetActive(false);
        StopCoroutine("Considerating");

        CardManager._instance.ForBid();
        isMyTerm = false;
    }
    /// <summary>
    /// 不抢地主
    /// </summary>
    public void NotBid()
    {
        //关闭倒计时
        countDownText.transform.parent.gameObject.SetActive(false);
        StopCoroutine("Considerating");

        CardManager._instance.NotBid();
        isMyTerm = false;
    }
    /// <summary>
    /// 卡牌排序（从大到小）
    /// </summary>
    protected void Sort()
    {
        cardInfos.Sort();
        cardInfos.Reverse();
    }

}
```

### 自身玩家类调整
其实就是重写了基类ToBiding方法，调用显示叫牌按钮（只有自身玩家才需要）
```csharp
using System;
using System.Collections.Generic;
using DG.Tweening;
using UnityEngine;
using UnityEngine.EventSystems;

/// <summary>
/// 自身玩家
/// </summary>
public class PlayerSelf : Player
{
    public GameObject prefab;   //预制件

    private Transform originPos1; //牌的初始位置
    private Transform originPos2; //牌的初始位置
    private List<GameObject> cards = new List<GameObject>();
    private bool canSelectCard = false;     //玩家是否可以选牌

    void Awake()
    {
        originPos1 = transform.Find("OriginPos1");
        originPos2 = transform.Find("OriginPos2");
    }

    //整理手牌
    public void GenerateAllCards()
    {
        //排序
        Sort();
        //计算每张牌的偏移
        var offsetX = originPos2.position.x - originPos1.position.x;
        //获取最左边的起点
        int leftCount = (cardInfos.Count / 2);
        var startPos = originPos1.position + Vector3.left * offsetX * leftCount;

        for (int i = 0; i < cardInfos.Count; i++)
        {
            //生成卡牌
            var card = Instantiate(prefab, originPos1.position, Quaternion.identity, transform);
            card.GetComponent<RectTransform>().localScale = Vector3.one * 0.6f;
            card.GetComponent<Card>().InitImage(cardInfos[i]);
            card.transform.SetAsLastSibling();
            //动画移动
            var tween = card.transform.DOMoveX(startPos.x + offsetX * i, 1f);
            if (i == cardInfos.Count - 1) //最后一张动画
            {
                tween.OnComplete(() => { canSelectCard = true; });
            }
            cards.Add(card);
        }
    }
    /// <summary>
    /// 销毁所有卡牌对象
    /// </summary>
    public void DestroyAllCards()
    {
        cards.ForEach(Destroy);
        cards.Clear();
    }
    /// <summary>
    /// 开始叫牌
    /// </summary>
    public override void ToBiding()
    {
        base.ToBiding();
        CardManager._instance.SetBidButtonActive(true);
    }
    /// <summary>
    /// 点击卡牌处理
    /// </summary>
    /// <param name="data"></param>
    public void CardClick(BaseEventData data)
    {
        //叫牌或出牌阶段才可以选牌
        if (canSelectCard &&
            (CardManager._instance.cardManagerState == CardManagerStates.Bid ||
             CardManager._instance.cardManagerState == CardManagerStates.Playing))
        {
            var eventData = data as PointerEventData;
            if (eventData == null) return;

            var card = eventData.pointerCurrentRaycast.gameObject.GetComponent<Card>();
            if (card == null) return;

            card.SetSelectState();
        }
    }
}
```

### 对手玩家类调整
主要模拟对手叫牌，如果是玩家回合，按下Q叫牌，按下W不叫
```csharp
using UnityEngine;

public class PlayerOther : Player
{
    void Update()
    {
        //如果当前是自己回合，模拟对手叫牌
        if (isMyTerm)
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
    }
}
```

### 卡牌管理类调整
首先需要改造发牌方法，现在区分发牌是发普通牌还是发发地主牌，根据发牌的不同类型，取牌堆里的不同牌，再判断是依次发牌，还是只发给地主牌。
然后具体实现玩家开始抢地主StartBiding，叫地主ForBid，不叫地主NotBid 3个方法：
StartBiding：从当前回合玩家开始叫牌；
ForBid：设置当前回合玩家是地主，并给地主发余下3张牌；
NotBid ：转向下个回合玩家开始叫牌；
```csharp
using System;
using System.Collections;
using System.IO;
using System.Linq;
using DG.Tweening;
using UnityEngine;

/// <summary>
/// 卡牌管理
/// </summary>
public class CardManager : MonoBehaviour
{
    public static CardManager _instance;    //单例


    public float dealCardSpeed = 20;  //发牌速度
    public Player[] Players;    //玩家的集合

    public GameObject coverPrefab;      //背面排预制件
    public Transform heapPos;           //牌堆位置
    public Transform[] playerHeapPos;    //玩家牌堆位置
    public CardManagerStates cardManagerState;

    private string[] cardNames;  //所有牌集合
    private int termStartIndex;  //回合开始玩家索引
    private int termCurrentIndex;  //回合当前玩家索引
    private int bankerIndex;        //当前地主索引
    private GameObject bidBtns;
    void Awake()
    {
        _instance = this;
        cardNames = GetCardNames();

        bidBtns = GameObject.Find("BidBtns");
        bidBtns.SetActive(false);
    }
    /// <summary>
    /// 洗牌
    /// </summary>
    public void ShuffleCards()
    {
        //进入洗牌阶段
        cardManagerState = CardManagerStates.ShuffleCards;
        cardNames = cardNames.OrderBy(c => Guid.NewGuid()).ToArray();
    }
    /// <summary>
    /// 开始发牌
    /// </summary>
    public IEnumerator DealCards()
    {
        //进入发牌阶段
        cardManagerState = CardManagerStates.DealCards;
        termCurrentIndex = termStartIndex;

        yield return DealHeapCards(false);
    }
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

            //下一个需要发牌者
            if (!ifForBid)
                SetNextPlayer();
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
            cardManagerState = CardManagerStates.Playing;
        }
    }
    /// <summary>
    /// 开始抢地主
    /// </summary>
    private void StartBiding()
    {
        cardManagerState = CardManagerStates.Bid;

        Players[termCurrentIndex].ToBiding();
    }
    /// <summary>
    /// 显示玩家手牌
    /// </summary>
    private void ShowPlayerSelfCards()
    {
        Players.ToList().ForEach(s =>
        {
            var player0 = s as PlayerSelf;
            if (player0 != null)
            {
                player0.GenerateAllCards();
            }
        });
    }
    /// <summary>
    /// 清空牌局
    /// </summary>
    public void ClearCards()
    {
        //清空所有玩家卡牌
        Players.ToList().ForEach(s => s.DropCards());

        //显示玩家手牌
        Players.ToList().ForEach(s =>
        {
            var player0 = s as PlayerSelf;
            if (player0 != null)
            {
                player0.DestroyAllCards();
            }
        });
    }
    /// <summary>
    /// 叫地主
    /// </summary>
    public void ForBid()
    {
        //设置当前地主
        bankerIndex = termCurrentIndex;

        //给地主发剩下的3张牌
        SetBidButtonActive(false);
        StartCoroutine(DealHeapCards(true));
    }
    /// <summary>
    /// 不叫
    /// </summary>
    public void NotBid()
    {
        SetBidButtonActive(false);
        SetNextPlayer();
        Players[termCurrentIndex].ToBiding();
    }
    /// <summary>
    /// 控制叫地主按钮是否显示
    /// </summary>
    /// <param name="isActive"></param>
    public void SetBidButtonActive(bool isActive)
    {
        bidBtns.SetActive(isActive);
    }

    /// <summary>
    /// 设置下一轮开始玩家
    /// </summary>
    public void SetNextTerm()
    {
        termStartIndex = (termStartIndex + 1) % Players.Length;
    }
    /// <summary>
    /// 设置下个回合玩家
    /// </summary>
    /// <returns></returns>
    public void SetNextPlayer()
    {
        termCurrentIndex = (termCurrentIndex + 1) % Players.Length;
    }
    private string[] GetCardNames()
    {
        //路径  
        string fullPath = "Assets/Resources/Images/Cards/";

        if (Directory.Exists(fullPath))
        {
            DirectoryInfo direction = new DirectoryInfo(fullPath);
            FileInfo[] files = direction.GetFiles("*.png", SearchOption.AllDirectories);

            return files.Select(s => Path.GetFileNameWithoutExtension(s.Name)).ToArray();
        }
        return null;
    }

    //开始新回合
    public void OnStartTermClick()
    {
        ClearCards();
        ShuffleCards();
        StartCoroutine(DealCards());
    }

}
```

### 总结
至此，我们【叫地主】功能大体完成了，来试试效果吧~
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171102124950435-161166063.gif) 

### 资源
[项目源码](https://github.com/lizzie2008/ChinesePoker.git) 