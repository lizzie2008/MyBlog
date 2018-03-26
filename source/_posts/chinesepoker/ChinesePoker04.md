---
title: Unity3D斗地主游戏 | (4) 出牌判断大小
tags:
  - C#
  - Unity 3D
  - Game Development
categories: 软件设计
date: 2017-06-04
---
![avatar](https://mysite.bj.bcebos.com/images/articles/9c93ff41-2251-428d-9a13-d553c20b6d65.jpg)

### 摘要
之前我们实现了叫地主、玩家和电脑自动出牌主要功能，但是还有个问题，出牌的时候，没有有效性检查和比较牌力大小。比如说，出牌3,4,5，目前是可以出牌的，然后下家可以出任何牌如3,6,9。
- 问题1：出牌检查有效性，就是出牌类型判断，像单张、对子、顺子、炸弹等等类型；
- 问题2：上家出牌后，下家再出牌的时候，要判断当前牌力是否大于上家的牌力；
那本篇我们主要解决以上2个问题。
<!-- more -->

### 卡牌信息类重构
首先，原先的卡牌类，已经实现了单张卡牌牌力的比较，但是有些复杂，我们先对这个比较逻辑进行优化。思路是卡牌的cardIndex就表示在此类型卡牌中的大小权重，所有，在初始化卡牌的过程中，对cardIndex进行特殊的处理：
cardIndex=（卡牌的原始索引+10）%13
比如：普通牌3--cardIndex=（3+10）%13=0，转换后排最小
普通牌J--cardIndex=（11+10）%13=8,转换后排第8张，如此，我们就可以轻松比较cardIndex，来判断单牌的实际大小了。
再看看优化后的代码，是不是比以前简洁很多？更主要的是，为了方便后面的复杂组合牌力的判断。
```csharp
public class CardInfo : IComparable
{
    public string cardName; //卡牌图片名
    public CardTypes cardType; //牌的类型
    public int cardIndex;      //牌在所在类型的索引3-10,J,Q,K,A,2(0-12)
    public bool isSelected;    //是否选中


    public CardInfo(string cardName)
    {
        this.cardName = cardName;
        var splits = cardName.Split('_');

        switch (splits[1])
        {
            case "1":
                cardType = CardTypes.Hearts;
                cardIndex = (int.Parse(splits[2]) + 10) % 13;
                break;
            case "2":
                cardType = CardTypes.Spades;
                cardIndex = (int.Parse(splits[2]) + 10) % 13;
                break;
            case "3":
                cardType = CardTypes.Diamonds;
                cardIndex = (int.Parse(splits[2]) + 10) % 13;
                break;
            case "4":
                cardType = CardTypes.Clubs;
                cardIndex = (int.Parse(splits[2]) + 10) % 13;
                break;
            case "joker":
                cardType = CardTypes.Joker;
                cardIndex = (int.Parse(splits[2]) + 10) % 13;
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
                if (cardIndex == other.cardIndex)
                {
                    return -cardType.CompareTo(other.cardType);
                }

                return cardIndex.CompareTo(other.cardIndex);
            }
        }
    }

}
```

### 出牌类型基类
接下来，那怎么判断出牌有效性和出牌的牌力大小判断呢？
我们这样想，每次出牌都是一组牌堆，那我们首先要判断这一组牌堆的类型，比如3带1，单张、炸弹等等；
其次，确定牌堆类型后，我们需要判断这个牌堆是否是合法的，其实就遍历验证是否符合上述的牌堆类型，如果满足，就认为合法，如果所有类型都不满足，则出牌无效，不允许出牌；
再者，怎么判断下家出牌的牌力要大于上家呢，这里我们还得有一个方法，判断相同类型的2个牌堆，牌堆1是否比牌堆2牌力大；
最后，为了实现电脑出牌的AI，还得有自动查找1个跟上家出牌类型一样的牌堆，而且比上家的牌堆大，如果有这种牌，则可以压住上家，否则自动过牌；
有了整体思路，我们这样设计，先定义一个虚基类--出牌类型基类，这里定义了所有需要子类牌堆类型实现的方法
```csharp
/// <summary>
    /// 出牌类型基类
    /// </summary>
    public abstract class FollowCardsBase
    {
        /// <summary>
        /// 验证类型
        /// </summary>
        /// <returns></returns>
        public abstract bool Validate(List<CardInfo> cardInfos);
        /// <summary>
        /// 找到最小满足的牌组
        /// </summary>
        /// <returns></returns>
        public abstract List<CardInfo> FindBigger(List<CardInfo> handCardInfos, List<CardInfo> cardInfos);
        /// <summary>
        /// 判断是否牌大过要比较的牌组
        /// </summary>
        /// <param name="handCardInfos"></param>
        /// <param name="cardInfos"></param>
        /// <returns></returns>
        public abstract bool IsBigger(List<CardInfo> handCardInfos, List<CardInfo> cardInfos);
    }
}
```
Validate方法：子类实现验证出牌是否满足此类型；
IsBigger方法：给定2个出牌的牌堆，判断此类型牌堆1是否满足牌力大于牌堆2；
FindBigger方法：在给定的手牌中，找出符合类型中满足牌力大于给定牌堆的组合；
这样，我们定义好基类，再利用子类去实现各自的方法，比如对子牌类型的子类，我们判断如果是对子，出牌的时候Validate判断是否也是对子，如果出牌是对子，而且IsBigger，就允许出牌；当然AI出牌的时候，通过FindBigger，找到满足对子类型，且比给定的对子牌力大的牌组，进行后续出牌操作。

### 定义各个类型牌型
因为斗地主涉及的牌型有很多，我们可以简单归纳一下。
我这里把单张和顺子作为一种牌组类型来实现，因为考虑顺子其实就是一种单张的特殊情景，只是约束条件是大于等于连续5张的单张牌。所以对子和连对、3带1或3带1的飞机等等，就都可以归为一类，个人感觉实现会简单些。
这里还是以单张和顺子举例：
```csharp
/// <summary>
/// 验证类型
/// </summary>
/// <returns></returns>
public override bool Validate(List<CardInfo> cardInfos)
{
    cardInfos.Sort();

    if (cardInfos.Count == 1)   //单张
    {
        return true;
    }
    else if (cardInfos.Count >= 5)  //顺子
    {
        //如果最大的牌是王或者2，则不是顺子
        if (cardInfos.Last().cardType == CardTypes.Joker || cardInfos.Last().cardIndex == 12)
            return false;

        for (int i = 0; i < cardInfos.Count - 2; i++)
        {
            if (cardInfos[i].cardIndex + 1 != cardInfos[i + 1].cardIndex)
                return false;
        }
        return true;
    }
    return false;
}
```
按照上一节所述，我们牌组类型子类，首先需要实现Validate方法，来验证是否属于单张或顺子。
- 如果是一张牌，毫无疑问，是单张
- 如果是大于等于5张牌，最大的牌不是王或者2，而且是连续的牌，则是顺子
其他情况肯定不是单张或顺子

```csharp
/// <summary>
/// 判断是否牌大过要比较的牌组
/// </summary>
/// <param name="handCardInfos"></param>
/// <param name="cardInfos"></param>
/// <returns></returns>
public override bool IsBigger(List<CardInfo> handCardInfos, List<CardInfo> cardInfos)
{
    cardInfos.Sort();
    handCardInfos.Sort();

    //牌数一样且最小牌比要比较的牌组的最小牌大
    if (handCardInfos.Count == cardInfos.Count && Validate(handCardInfos) && Validate(cardInfos))
    {
        if (handCardInfos[0].CompareTo(cardInfos[0]) > 0)
            return true;
    }
    return false;
}
```
接着，怎么判断2组牌组的牌力大小呢？
- 第一步，将2牌组按照从小到大排序
- 判断2牌组的牌数是否一样
- 判断2牌组的类型是否都是单张或顺子
- 如果满足以上2个条件，再判断2牌组的第一张大小
- 如果牌组1的第一张大于牌组2的第一张，则可以认为牌组1牌力大于牌组2
- 反之也成立
- 否则，如果相等，则牌力一样

```csharp
/// <summary>
/// 找到最小满足的牌组
/// </summary>
/// <returns></returns>
public override List<CardInfo> FindBigger(List<CardInfo> handCardInfos, List<CardInfo> cardInfos)
{
    cardInfos.Sort();
    handCardInfos.Sort();

    if (cardInfos.Count == 1)   //单张
    {
        var cardInfo = handCardInfos.FirstOrDefault(s => s.CompareTo(cardInfos[0]) > 0 && s.cardIndex != cardInfos[0].cardIndex);
        if (cardInfo != null)
        {
            var result = new List<CardInfo>();
            result.Add(cardInfo);
            return result;
        }
        return null;
    }

    else if (cardInfos.Count >= 5)  //顺子
    {
        var count = handCardInfos.Count - cardInfos.Count;

        if (count >= 0)
        {
            //手牌比牌组多count，则有count + 1可能满足牌组
            for (int i = 0; i < count + 1; i++)
            {
                var mayBiggerCardInfos = handCardInfos.Skip(i).Take(cardInfos.Count).ToList();
                //是顺子，且最小的牌比要比较的牌组最小牌要大
                if (Validate(mayBiggerCardInfos) && mayBiggerCardInfos[0].CompareTo(cardInfos[0]) > 0 && mayBiggerCardInfos[0].cardIndex != cardInfos[0].cardIndex)

                {
                    return mayBiggerCardInfos;
                }
            }
            return null;
        }
        return null;
    }
    return null;
}
```
再来看，我们怎么根据给定的单张或顺子，在手牌中找到对应牌力大于上家的牌组；
这里提供了一个简单的实现方式，找到最小满足的牌组，当然，如果要实现智能的电脑出牌的AI，或者智能提示出牌，肯定要复杂很多，就不在探讨范围内了。
- 第一步，将2牌组按照从小到大排序
- 如果上家牌是单张，那简单，从手牌中找到第1张满足牌力大于上家牌的单张即可；
- 如果上家牌是顺子，判断手牌比上家牌的牌数只差，比如手牌17张，上家牌是5张的顺子，那就是17-5=12，理论上有12+1最多可能满足的牌组组合；
- 那从第一张手牌开始，遍历12+1次，每次取当前手牌后的5张牌，判断是否比上家牌牌力大，如果不满足，则继续下轮遍历；
- 如果找到，则返回该牌组，可以认为这牌组牌力大于上家牌，且类型为单张或顺子，牌数跟上家牌一样；
- 如果遍历完还没找到，认为手牌中没有大于上家牌的牌组，游戏玩家可以跳过次回合；

至此，我们的单张和顺子类型的出牌检验逻辑，大体上就完成了。接下来，我们只需要稍微修改下之前的出牌逻辑~

### 出牌逻辑调整
这里需要调整2处，一方面，在玩家出牌时，要增加判断，如果玩家选择的牌堆，牌力不够，需要提示玩家，很简单，不在复述；
再来看电脑出牌的逻辑，我们在PlayOthre类中，增加以下这段代码：
```csharp
if (CardManager._instance.cardManagerState == CardManagerStates.Playing)
{
    if (Input.GetKeyDown(KeyCode.Q)) //出牌
    {
        var singleCards = new SingleCards();
        var cardInfos = singleCards.FindBigger(this.cardInfos, CardManager._instance.currentCardInfos);
        if (cardInfos != null)
        {
            cardInfos.ForEach(s => s.isSelected = true);
            ForFollow();
        }
        else
        {
            NotFollow();
        }
    }
}
```
电脑AI出牌的时候，通过FindBigger，去匹配手牌中有没有满足牌力大于上家牌的牌组类型，如果有，将返回的牌组出出去，如果没有，则自动过牌。
那现在玩家出牌、电脑AI出牌就可以正常处理了，我们来看一下效果：
![avatar](https://mysite.bj.bcebos.com/images/201802/371995-20171204145106951-402076610.gif) 

### 写在最后
我们的斗地主游戏开发有段时间了，本文就作为阶段性的结束篇~当然，远算不上是一个成品游戏，我只是简单的实现了部分功能，有些代码现在看来还是偷工减料。要完成一个成品游戏，需要大量的精力和时间，条件也不允许，以后有机会的话，可能会对这个项目完善和优化。
这是我第一次写一个系列的东西，写得不好请大家多多包涵~推出这个系列，我的主旨是想和大家分享下Unity3D开发一个斗地主游戏的整体架构和设计模式，虽然是个半成品，但是有些代码我是真的用心去写的，尽量的把我实现的思路和对游戏的理解展现给大家。就像一千个人眼中有一千个哈姆雷特，由于我们对游戏理解的不同，同样的斗地主游戏，不同的开发者，实现的方法可能就是不同的。我能做的，我希望做的，就是把个人的思想剖析给你们，如果你们能理解，或者对你们有所帮助，也是我的幸事。
最后，谢谢各位的一路陪伴。也欢迎大家关注，我们一同学习，共同进步，以后会坚持出新的系列！

### 资源
[项目源码](https://github.com/lizzie2008/ChinesePoker.git) 