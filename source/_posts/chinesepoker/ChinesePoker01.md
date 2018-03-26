---
title: Unity3D斗地主游戏 | (1) 发牌功能实现
tags:
  - C#
  - Unity 3D
  - Game Development
categories: 软件设计
date: 2017-06-01
---
![avatar](https://mysite.bj.bcebos.com/images/articles/9c93ff41-2251-428d-9a13-d553c20b6d65.jpg)

### 摘要
园子荒废多年，闲来无事，用Unity3D来尝试做一个简单的小游戏，一方面是对最近研究的Unity3D有点总结，一方面跟广大的园友相互学习和提高。话不多说，进入正题~
<!-- more -->

### 创建项目
1.创建Unity2017的2D项目，暂且叫做ChinesePoker吧，就用自带的UGUI来编辑UI， 目前只导入iTween插件，用来方便控制动画效果。
目录结构如下：
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171031112256418-143063490.png)
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171031112750886-150146473.png)  
考虑卡牌需要动态生成，我把图片资源放到Resource目录，并按照Card_类型（大小王，红桃，黑桃，方片，梅花 ）_数字（卡牌所在类型中的数字）命名。
素材都是网上找的，没有美工基础，就是这么个意思，大家将就看吧，：）
2.建第一个场景，默认叫001_Playing，作为主要玩牌的场景，暂时作为第1个场景，后期新场景添加进来，我们可能再调整场景的顺序。
添加一个UI->Image,选择一个背景图片；
添加3个UI->Canvas，分别取名叫Player0,Player1,Player2,代表玩家，对手1，对手2；
每个Player底下，添加一个Image，选择卡牌背面图片，分别表示发牌时各自牌堆的位置，并在桌面放置一个总牌堆的位置，默认not active；
建一个卡牌的图片，命名为Card，并作为预制件，放入Player0中间一个，稍微偏移一定位置再放置一个，用来计算每张牌跟临牌相对位置，设置not active；
建一个卡牌的背面图片，命名Cover，也作为预制件；
添加一个测试按钮TestButton;
差不多了，大概结构如下：
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171031115250402-1107019040.png)  

### 创建卡牌、玩家信息
1.新建CardInfo类，主要不要继承默认的MonoBehaviour类，用来作为卡牌的实体类；
实现IComparable接口，后面手牌排序会用到。
```csharp
public class CardInfo : IComparable
{
    public string cardName; //卡牌图片名
    public CardTypes cardType; //牌的类型
    public int cardIndex;      //牌在所在类型的索引1-13

    public CardInfo(string cardName)
    {
        this.cardName = cardName;
        var splits = cardName.Split('_');

        switch (splits[1])
        {
            case "1":
                cardType = CardTypes.Hearts;
                cardIndex = int.Parse(splits[2]);
                break;
            case "2":
                cardType = CardTypes.Spades;
                cardIndex = int.Parse(splits[2]);
                break;
            case "3":
                cardType = CardTypes.Diamonds;
                cardIndex = int.Parse(splits[2]);
                break;
            case "4":
                cardType = CardTypes.Clubs;
                cardIndex = int.Parse(splits[2]);
                break;
            case "joker":
                cardType = CardTypes.Joker;
                cardIndex = int.Parse(splits[2]);
                break;
            default:
                throw new Exception(string.Format("卡牌文件名{0}非法！", cardName));
        }
    }

    //卡牌大小比较
    public int CompareTo(object obj)
    {
        CardInfo other = obj as CardInfo;

        if (other == null)
            throw new Exception("比较对象类型非法！");

        //如果当前是大小王
        if (cardType == CardTypes.Joker)
        {
            //对方也是大小王
            if (other.cardType == CardTypes.Joker)
            {
                return cardIndex.CompareTo(other.cardIndex);
            }
            //对方不是大小王
            return 1;
        }
        //如果是一般的牌
        else
        {
            //对方是大小王
            if (other.cardType == CardTypes.Joker)
            {
                return -1;
            }
            //如果对方也是一般的牌
            else
            {
                //计算牌力
                var thisNewIndex = (cardIndex == 1 || cardIndex == 2) ? 13 + cardIndex : cardIndex;
                var otherNewIndex = (other.cardIndex == 1 || other.cardIndex == 2) ? 13 + other.cardIndex : other.cardIndex;

                if (thisNewIndex == otherNewIndex)
                {
                    return -cardType.CompareTo(other.cardType);
                }

                return thisNewIndex.CompareTo(otherNewIndex);
            }
        }
    }

}
```
2.Card预制件上，添加Card脚本，主要保存对应CardInfo信息、选中状态，并加载卡牌图片；
```csharp
public class Card : MonoBehaviour
{
    private Image image;        //牌的图片
    private CardInfo cardInfo;  //卡牌信息
    private bool isSelected;    //是否选中

    void Awake()
    {
        image = GetComponent<Image>();
    }

    /// <summary>
    /// 初始化图片
    /// </summary>
    /// <param name="cardInfo"></param>
    public void InitImage(CardInfo cardInfo)
    {
        this.cardInfo = cardInfo;
        image.sprite = Resources.Load("Images/Cards/" + cardInfo.cardName, typeof(Sprite)) as Sprite;
    }
    /// <summary>
    /// 设置选择状态
    /// </summary>
    public void SetSelectState()
    {
        if (isSelected)
        {
            iTween.MoveTo(gameObject, transform.position - Vector3.up * 10f, 1f);
        }
        else
        {
            iTween.MoveTo(gameObject, transform.position + Vector3.up * 10f, 1f);
        }

        isSelected = !isSelected;
    }
}
```
3.考虑玩家分为2种类型，先创建一个公共的基类，实现玩家公共的方法，比如增加一张卡牌、清空所有卡片、排序等；
```csharp
public class Player : MonoBehaviour
{
    protected List<CardInfo> cardInfos = new List<CardInfo>();  //个人所持卡牌

    private Text cardCoutText;

    void Start()
    {
        cardCoutText = transform.Find("HeapPos/Text").GetComponent<Text>();
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

    protected void Sort()
    {
        cardInfos.Sort();
        cardInfos.Reverse();
    }
}
```
4.添加第一种玩家（自身玩家）PlayerSelf，继承Player，并挂载到Player0对象上；
实现整理手牌的逻辑：发牌后，从中间的位置，根据大小依次将牌展开；
获取牌面点击事件，将牌选中或取消选中；
```csharp
public class PlayerSelf : Player
{
    public GameObject prefab;   //预制件

    private Transform originPos1; //牌的初始位置
    private Transform originPos2; //牌的初始位置
    private List<GameObject>  cards=new List<GameObject>();

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

            var targetPos = startPos + Vector3.right * offsetX * i;
            card.transform.SetAsLastSibling();
            //动画移动
            iTween.MoveTo(card, targetPos, 2f);

            cards.Add(card);
        }
    }

    public void DestroyAllCards()
    {
        cards.ForEach(Destroy);
        cards.Clear();
    }

    /// <summary>
    /// 点击卡牌处理
    /// </summary>
    /// <param name="data"></param>
    public void CardClick(BaseEventData data)
    {
        //叫牌或出牌阶段才可以选牌
        if (CardManager._instance.cardManagerState == CardManagerStates.Bid ||
            CardManager._instance.cardManagerState == CardManagerStates.Playing)
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
5.添加另一种玩家（对手玩家）PlayerOther，继承Player，并挂载到Player1，Player2对象上；
暂时没有实现任何其他功能：
```csharp
public class PlayerOther : Player
{
   
}
```

### 实现发牌逻辑
在Camera上添加卡牌管理脚本：CardManager
1.实现洗牌逻辑，这里用生成GUID随机性后排序，达到洗牌的目的；
2.记录当前发牌回合，每发一张牌，跳转给下一个玩家；
3.记录当前玩牌回合（将来可能用到），每玩一局，跳转下个玩家开始发牌；
4.发牌逻辑：
设置牌堆的显示，动画依次给每位玩家发一张卡牌，发完牌后，隐藏牌堆，并将玩家的卡牌排序并展示；
```csharp
public class CardManager : MonoBehaviour
{
    public float dealCardSpeed = 20;  //发牌速度
    public Player[] Players;    //玩家的集合

    public GameObject coverPrefab;      //背面排预制件
    public Transform heapPos;           //牌堆位置
    public Transform[] playerHeapPos;    //玩家牌堆位置


    public static CardManager _instance;    //单例
    public CardManagerStates cardManagerState;

    private string[] cardNames;  //所有牌集合
    private int termStartIndex = 0;  //回合开始玩家索引
    private int termCurrentIndex = 0;  //回合当前玩家索引
    private List<GameObject> covers = new List<GameObject>();   //背面卡牌对象，发牌结束后销毁

    void Awake()
    {
        _instance = this;

        cardNames = GetCardNames();
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
    /// 发牌
    /// </summary>
    public IEnumerator DealCards()
    {
        //进入发牌阶段
        cardManagerState = CardManagerStates.DealCards;

        //显示牌堆
        heapPos.gameObject.SetActive(true);
        playerHeapPos.ToList().ForEach(s => { s.gameObject.SetActive(true); });

        foreach (var cardName in cardNames)
        {
            //给当前玩家发一张牌
            Players[termCurrentIndex].AddCard(cardName);

            var cover = Instantiate(coverPrefab, heapPos.position, Quaternion.identity, heapPos.transform);
            cover.GetComponent<RectTransform>().localScale = Vector3.one;
            covers.Add(cover);
            iTween.MoveTo(cover, playerHeapPos[termCurrentIndex].position, 0.3f);

            yield return new WaitForSeconds(1 / dealCardSpeed);

            //下一个需要发牌者
            SetNextPlayer();
        }

        //隐藏牌堆
        heapPos.gameObject.SetActive(false);
        playerHeapPos[0].gameObject.SetActive(false);

        //显示玩家手牌
        Players.ToList().ForEach(s =>
        {
            var player0 = s as PlayerSelf;
            if (player0 != null)
            {
                player0.GenerateAllCards();
            }
        });
        //动画结束，进入叫牌阶段
        yield return new WaitForSeconds(2f);
        covers.ForEach(Destroy);
        cardManagerState = CardManagerStates.Bid;
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
    /// 获取下个玩家
    /// </summary>
    /// <returns></returns>

    private void SetNextPlayer()
    {
        termCurrentIndex = (termCurrentIndex + 1) % Players.Length;
    }
    /// <summary>
    /// 切换开始回合玩家
    /// </summary>
    public void SetNextTerm()
    {
        termStartIndex = (termStartIndex + 1) % Players.Length;
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

    //for test
    public void OnTestClick()
    {
        ClearCards();
        ShuffleCards();
        StartCoroutine(DealCards());
    }

}
```

### 总结
其实发牌后的动画，可以由override基类的方法，交由Player子类处理，不用CardManager集中管理，大家可以优化一下。
大体逻辑完成，我们验证下效果吧：
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171031110939215-299047755.gif) 

### 资源
[项目源码](https://github.com/lizzie2008/ChinesePoker.git) 