---
title: 算法题丨Permutation Sequence
tags:
  - 算法
  - 编程技巧
  - 数据结构
categories: 计算机基础
date: 2017-01-11
---
![avatar](https://mysite.bj.bcebos.com/images/articles/d21ee518-d67e-4a61-9a7f-cdd43df6bf89.jpg)

### 描述
>The set [1,2,3,…,n] contains a total of n! unique permutations.

### 示例
```
By listing and labeling all of the permutations in order,
We get the following sequence (ie, for n = 3):

"123"
"132"
"213"
"231"
"312"
"321"
Given n and k, return the kth permutation sequence.

Note: Given n will be between 1 and 9 inclusive.
```
<!-- more -->

### 算法分析
**难度**：中
**分析**：前面章节我们解释了全排列的概念，这节算法要求给定的{1,2...n}集合，求集合的全排列中第k条排列。
**思路**：首先最简单的方法，因为我们上一节已经实现了下一个排列方法Next Permutation，那我们将该方法执行(k-1)次，便可以获得第k条排列。但是这算是最优的解法，因为这
个方法把前 k 个排列全部求出来了，比较浪费。所以我们考虑有没有方法直接求第 k 个排列：
不妨 n = 4, 所以集合为 {1, 2, 3, 4}
我们列出全排列的组合，可以先分为4组：
1 + ({2, 3, 4}的全排列)
2 + ({1, 3, 4}的全排列)
3 + ({1, 2, 4}的全排列)
4 + ({1, 2, 3}的全排列)
我们再看看每组的排列的个数，因为第一个元素已经确定，所以每组个数=剩下3个元素的排列个数=3\*2\*1=6个，当然全部的排列个数=4\*6=24个。比如题目要求第14个排列（k=13，因为索引下标从0开始），很明显应该落在3 + ({1, 2, 4}的全排列)这个组合区间（下标为k/(n-1)! = 13/(4-1)! = 13/3! = 13/6 = 2）。
于是，问题变成接着在{1, 2, 4}这个组合中找解，同上我们将这个组合分成3组：
1 + ({2, 4}的全排列)
2 + ({1, 4}的全排列)
4 + ({1, 2}的全排列)
因为k此时由于上个步骤，截取6\*2=12个，相对该排列，应当下标为k = k - (之前组合个数) \* (n-1)! = k - 2\*(n-1)! = 13 - 2\*(3)! = 1。
因为第2步，每组的排列个数为=2\*1=2个，所以落在下标为 k / (n - 2)! = 1 / (4-2)! = 1 / 2! = 0的区间，即1 + ({2, 4}的全排列)。
经过以上，我们已经确定排列为{3,1,...}，接下来继续递归，在{2, 4}中找解，这时k=1，方法同上，不在多述，很容易知道第3部的解为4，最后只剩下元素2。
所以最终，获得题目要求的排列{3,1,4,2}。

### 代码示例(C#)
```csharp
public string GetPermutation(int n, int k)
{
    var sb = new StringBuilder();
    var nums = new List<int>();
    //fact记录n的阶乘
    int fact = 1;
    for (int i = 1; i <= n; i++)
    {
        fact *= i;
        nums.Add(i);
    }
    for (int i = 0, l = k - 1; i < n; i++)
    {
        //计算组合内相对的下标
        fact /= (n - i);
        int index = (l / fact);
        sb.Append(nums.ElementAt(index));
        nums.Remove(nums.ElementAt(index));
        //截取剩下的索引长度，用于下次遍历
        l -= index * fact;
    }
    return sb.ToString();
}
```

### 复杂度
- **时间复杂度**：*O* (n²). 
- **空间复杂度**：*O* (1).

### 附录
- [系列目录索引](/posts/algorithm/index/)
- [代码实现(C#版)](https://github.com/lizzie2008/LeetCode.git)
- 相关算法
	- [Next Permutation](/posts/algorithm/Next Permutation/)
	- [Permutations](/posts/algorithm/Permutations/)
	- [Permutations II](/posts/algorithm/Permutations II/)
	- [Combinations](/posts/algorithm/Combinations/)