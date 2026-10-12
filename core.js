(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.SlowlyCore = api;
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  const VERSION = 2, DAY = 86400000;
  const pad = n => String(n).padStart(2, '0');
  const dateKey = (value = new Date()) => { const d = value instanceof Date ? value : new Date(value); return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}`; };
  const uid = (prefix='id') => `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2,9)}`;
  const iso = () => new Date().toISOString();
  const clone = value => JSON.parse(JSON.stringify(value));
  const DEFAULT_TASKS = ['今天没有冲动购物','记录今日消费','整理环境5分钟','阅读或学习20分钟','运动或散步20分钟'];
  const MONTHS = [
    ['消费与物品大盘点','看清拥有与真正需要'],['建立财务系统','让每一笔钱更有方向'],['空间断舍离','让房间重新呼吸'],['身体健康重建','温柔地照顾身体'],
    ['数字断舍离与注意力管理','把注意力还给自己'],['核心技能学习','做出第一个作品'],['生活技能提升','建立稳稳的日常'],['培养低消费爱好','发现不花钱的快乐'],
    ['人际关系重建','靠近值得的人'],['职业能力升级','让成长被看见'],['建立稳定生活系统','形成自己的节奏'],['年度复盘与下一年规划','带着收获继续出发']
  ];
  const WEEK_NAMES = [
    '记录一周全部支出','盘点常用物品','清理购物推送','建立愿望清单','复盘近三个月消费','取消闲置订阅','建立月度预算','完成无冲动购物周',
    '整理衣柜','清理浴室与厨房','整理书桌与抽屉','完成空间复盘','连续记录睡眠','完成三次运动','尝试自己备餐','制定运动计划',
    '整理社交媒体关注','连续阅读七天','一天不刷购物平台','输出一本书总结','选择核心技能','累计学习五小时','完成小练习','发布第一个作品',
    '学习三道家常菜','学习衣物护理','完成冰箱清单','整理省钱技巧','探索免费公园','完成生活摄影','体验零成本创作','写下不花钱的快乐',
    '联系一位老朋友','安排低成本交流','完成家庭共同活动','写下关系边界','整理工作成果','优化重复工作','完成职业小项目','更新简历或作品集',
    '复盘稳定习惯','设计晨间流程','设计晚间流程','写一份每周SOP','统计年度消费','统计断舍离成果','写给一年前的信','制定下一年规则',
    '补做最想完成的挑战','整理年度照片和记录','安排一周低负担生活','感谢支持过自己的人'
  ];
  function goal(title,category,target,unit,startDate){const end=new Date(startDate+'T12:00:00');end.setDate(end.getDate()+364);return{id:uid('goal'),title,category,target,unit,startDate,endDate:dateKey(end),status:'进行中',updatedAt:iso()};}
  function defaultRewards(now){return [['一个自由下午',50],['家庭电影夜',100],['免费城市探索',200],['特别体验日',400]].map(([title,cost])=>({id:uid('reward'),title,cost,active:true,updatedAt:now}));}
  function newState(seed={}){
    const start=seed.startDate||dateKey(),now=iso();
    return {schemaVersion:VERSION,revision:0,updatedAt:now,onboardingComplete:false,
      profile:{nickname:seed.nickname||'慢慢',focus:'财务与生活秩序',createdAt:now,updatedAt:now},
      settings:{startDate:start,currency:'CNY',savingGoal:12000,declutterGoal:200,calmHours:72,nonEssentialRule:'非生活必需、非计划内且可延后购买的支出',taskLabels:DEFAULT_TASKS.slice(),privacyMode:true},
      annualGoals:[goal('年度额外储蓄','财务',12000,'元',start),goal('合理处理闲置物品','断舍离',200,'件',start),goal('累计学习','个人成长',300,'小时',start),goal('完成技能作品','个人成长',4,'个',start),goal('完成周挑战','生活重建',52,'周',start)],
      monthlyPlans:MONTHS.map((m,i)=>({id:`month_${i+1}`,month:i+1,title:m[0],description:m[1],review:'',updatedAt:now})),
      weeklyChallenges:WEEK_NAMES.map((title,i)=>({id:`week_${i+1}`,week:i+1,month:Math.min(12,Math.floor(i/4)+1),title,completed:false,completedAt:null,updatedAt:now})),
      checkins:{},transactions:[],wishes:[],inventory:[],declutter:[],learningSessions:[],rewards:defaultRewards(now),pointEvents:[],redemptions:[],reviews:[],noSpendDays:{},moodEntries:[],tombstones:[]};
  }
  function dayNumber(start,date=dateKey()){return Math.floor((new Date(date+'T12:00:00')-new Date(start+'T12:00:00'))/DAY)+1;}
  function challengeDay(state,date=dateKey()){return Math.max(1,Math.min(365,dayNumber(state.settings.startDate,date)));}
  function tasksFor(state,date){return state.checkins[date]?.tasks||state.settings.taskLabels.map(()=>false);}
  function checkinScore(tasks){const n=tasks.filter(Boolean).length;return n>=3?5+(n===5?3:0):0;}
  function eventKey(type,ref){return `${type}:${ref}`;}
  function syncPointEvents(state,date){
    const score=checkinScore(tasksFor(state,date)),desired=[];
    if(score>=5)desired.push({key:eventKey('daily3',date),type:'每日达标',points:5,ref:date});
    if(score===8)desired.push({key:eventKey('daily5',date),type:'每日全完成',points:3,ref:date});
    state.pointEvents=state.pointEvents.filter(e=>!e.key.endsWith(`:${date}`)||desired.some(d=>d.key===e.key));
    desired.forEach(d=>{if(!state.pointEvents.some(e=>e.key===d.key))state.pointEvents.push({...d,id:uid('pt'),createdAt:iso(),updatedAt:iso()});});
  }
  function touch(state){state.revision=Number(state.revision||0)+1;state.updatedAt=iso();}
  function setCheckin(state,date,index,checked){const tasks=tasksFor(state,date).slice();tasks[index]=!!checked;state.checkins[date]={tasks,updatedAt:iso()};syncPointEvents(state,date);touch(state);return state;}
  function setWeekly(state,id,completed){const item=state.weeklyChallenges.find(w=>w.id===id);if(!item)return state;item.completed=!!completed;item.completedAt=completed?iso():null;item.updatedAt=iso();const key=eventKey('week',id);state.pointEvents=state.pointEvents.filter(e=>e.key!==key);if(completed)state.pointEvents.push({id:uid('pt'),key,type:'周挑战',points:20,ref:id,createdAt:iso(),updatedAt:iso()});touch(state);return state;}
  function points(state){return state.pointEvents.reduce((s,e)=>s+Number(e.points||0),0)-state.redemptions.reduce((s,r)=>s+Number(r.cost||0),0);}
  function streak(state,until=dateKey()){let total=0,d=new Date(until+'T12:00:00');while(total<365){if(tasksFor(state,dateKey(d)).filter(Boolean).length<3)break;total++;d.setDate(d.getDate()-1);}return total;}
  function totals(state){return state.transactions.reduce((a,t)=>{const n=Number(t.amount||0);a[t.type]=(a[t.type]||0)+n;return a;},{income:0,necessary:0,nonessential:0,saving_in:0,saving_out:0});}
  function savingTotal(state){const t=totals(state);return(t.saving_in||0)-(t.saving_out||0);}
  function upsert(list,record){const i=list.findIndex(x=>x.id===record.id);if(i>=0)list[i]={...list[i],...record,updatedAt:iso()};else list.push({...record,id:record.id||uid('rec'),createdAt:record.createdAt||iso(),updatedAt:iso()});}
  function remove(state,collection,id){const list=state[collection];if(!Array.isArray(list))return;const i=list.findIndex(x=>x.id===id);if(i>=0){list.splice(i,1);state.tombstones.push({id:uid('del'),collection,recordId:id,deletedAt:iso(),updatedAt:iso()});touch(state);}}
  function merge(local,remote){
    if(!remote)return clone(local);if(!local)return clone(remote);const out=clone(new Date(local.updatedAt||0)>=new Date(remote.updatedAt||0)?local:remote);
    const cols=['annualGoals','monthlyPlans','weeklyChallenges','transactions','wishes','inventory','declutter','learningSessions','rewards','pointEvents','redemptions','reviews','moodEntries','tombstones'];
    cols.forEach(k=>{const map=new Map();[...(remote[k]||[]),...(local[k]||[])].forEach(x=>{const key=x.id||x.key,old=map.get(key);if(!old||new Date(x.updatedAt||x.createdAt||0)>=new Date(old.updatedAt||old.createdAt||0))map.set(key,x);});out[k]=[...map.values()];});
    out.checkins={};
    new Set([...Object.keys(remote.checkins||{}),...Object.keys(local.checkins||{})]).forEach(k=>{const a=local.checkins?.[k],b=remote.checkins?.[k];out.checkins[k]=!a?b:!b?a:(new Date(a.updatedAt||0)>=new Date(b.updatedAt||0)?a:b);});
    out.noSpendDays={...(remote.noSpendDays||{}),...(local.noSpendDays||{})};
    (out.tombstones||[]).forEach(t=>{if(Array.isArray(out[t.collection]))out[t.collection]=out[t.collection].filter(x=>x.id!==t.recordId);});out.revision=Math.max(local.revision||0,remote.revision||0)+1;out.updatedAt=iso();return out;
  }
  function migrate(raw){const base=newState();if(!raw||typeof raw!=='object')return base;const out={...base,...raw,profile:{...base.profile,...raw.profile},settings:{...base.settings,...raw.settings}};out.schemaVersion=VERSION;return out;}
  function validateBackup(obj){if(!obj||obj.app!=='slowly'||!obj.data)throw new Error('不是“慢慢来”备份文件');if(!Array.isArray(obj.data.transactions)||!obj.data.settings||!obj.data.profile)throw new Error('备份结构不完整');return migrate(obj.data);}
  return {VERSION,DEFAULT_TASKS,MONTHS,WEEK_NAMES,dateKey,uid,iso,clone,newState,dayNumber,challengeDay,tasksFor,checkinScore,setCheckin,setWeekly,points,streak,totals,savingTotal,touch,upsert,remove,merge,migrate,validateBackup};
});

