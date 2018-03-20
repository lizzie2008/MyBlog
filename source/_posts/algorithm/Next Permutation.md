---
title: 算法题丨Next Permutation
tags:
  - 算法
  - 编程技巧
  - 数据结构
categories: 计算机基础
date: 2017-01-10
---
![avatar](https://bj.bcebos.com/v1/mysite/images/articles/e46fea39-144a-47f4-abb6-ca7c7324f04d.jpg)
### 描述
>Implement next permutation, which rearranges numbers into the lexicographically next greater permutation of numbers.
If such arrangement is not possible, it must rearrange it as the lowest possible order (ie, sorted in ascending order).
The replacement must be in-place, do not allocate extra memory.

### 示例
```
Here are some examples. Inputs are in the left-hand column 
and its corresponding outputs are in the right-hand column.
1,2,3 → 1,3,2
3,2,1 → 1,2,3
1,1,5 → 1,5,1
```
<!-- more -->
### 算法分析
**难度**：中
**分析**：这里需要跟大家介绍一下相关的几个概念：
>**排列（Arrangement）**，简单讲是从N个不同元素中取出M个，按照一定顺序排成一列，通常用A(M,N)表示。当M=N时，称为**全排列（Permutation）**。
例如对于一个集合A={1,2,3}，首先获取全排列a1: 1,2,3；然后获取下一个排列a2: 1,3,2；
按此顺序，A的全排列如下，共6种：
a1: 1,2,3;　　a2: 1,3,2;　　a3: 2,1,3;　　a4: 2,3,1;　　a5: 3,1,2;　　a6: 3,2,1;　　
从数学角度讲，全排列的个数A(N,N)=(N)\*(N-1)\*...\*2\*1=N!，但从编程角度，如何获取所有排列？那么就必须按照某种顺序逐个获得下一个排列，通常按照升序顺序（**字典序lexicographically**）获得下一个排列。
对于给定的任意一种全排列，如果能求出下一个全排列的情况，那么求得所有全排列情况就容易了，也就是题目要求实现的**下一个全排列算法（Next Permutation）**。

**思路**：
设目前有一个集合的一种全排列情况A : 1,5,8,4,7,6,5,3,1，求取下一个排列的步骤如下：
```
/** Tips: next permuation based on the ascending order sort
 * sketch :
 * current: 1   5  8  4  7  6  5  3  1
 *                    |        |     |
 *          find i----+        j     +----end
 * swap i and j :
 *          1   5  8  5  7  6  4  3  1
 *                    |        |     |
 *               j----+        i     +----end
 * reverse j+1 to end :
 *          1   5  8  5  1  3  4  6  7
 *                    |              |
 *          find j----+              +----end
 * */
```

具体方法为：
a）从后向前查找第一个相邻元素对(i,i+1)，并且满足A[i] < A[i+1]。
易知，此时从j到end必然是降序。可以用反证法证明，请自行证明。
b）在[i+1,end)中寻找一个最小的j使其满足A[i]<A[j]。
由于[j,end)是降序的，所以必然存在一个j满足上面条件；并且可以从后向前查找第一个满足A[i]<A[j]关系的j，此时的j必是待找的j。
c）将i与j交换。
此时，i处变成比i大的最小元素，因为下一个全排列必须是与当前排列按照升序排序相邻的排列，故选择最小的元素替代i。
易知，交换后的[j,end)仍然满足降序排序。
d）逆置[j,end)
由于此时[j,end)是降序的，故将其逆置。最终获得下一全排序。
注意：如果在步骤a）找不到符合的相邻元素对，即此时i=begin，则说明当前[begin,end)为一个降序顺序，即无下一个全排列，于是将其逆置成升序。
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/e7855a48-6c57-482c-80b8-c6e81a49f161.gif)

### 代码示例(C#)
```csharp
public void NextPermutation(int[] nums)
{
    int i = nums.Length - 2;
    //末尾向前查找，找到第一个i，使得A[i] < A[i+1]
    while (i >= 0 && nums[i + 1] <= nums[i])
    {
        i--;
    }
    if (i >= 0)
    {
        //从i下标向后找第一个j,使得A[i]<A[j]
        int j = nums.Length - 1;
        while (j >= 0 && nums[j] <= nums[i])
        {
            j--;
        }
        //交换i，j
        Swap(nums, i, j);
    }
    //逆置j之后的元素
    Reverse(nums, i + 1);
} 
    
//逆置排序
private void Reverse(int[] nums, int start)
{
    int i = start, j = nums.Length - 1;
    while (i < j)
    {
        Swap(nums, i, j);
        i++;
        j--;
    }
}

//交换
private void Swap(int[] nums, int i, int j)
{
    int temp = nums[i];
    nums[i] = nums[j];
    nums[j] = temp;
} 
```
### 复杂度
- **时间复杂度**：*O* (n). 
- **空间复杂度**：*O* (1).

### 附录
- [系列目录索引](/posts/algorithm/index/)
- [代码实现(C#版)](https://github.com/lizzie2008/LeetCode.git)
	- [Permutation Sequence](/posts/algorithm/Permutation Sequence/)
	- [Permutations](/posts/algorithm/Permutations/)
	- [Permutations II](/posts/algorithm/Permutations II/)
	- [Combinations](/posts/algorithm/Combinations/)