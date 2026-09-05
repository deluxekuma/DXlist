const CHART_ID = 11377;
const MUSIC_ID = 1377;
const BPM = 222;
const CANVAS_SIZE = 800;
const CENTER_RADIUS = 0.15; // 中央圓
const JUDGE_LINE_RADIUS = 0.35; // 判定線位置
const NOTE_SPAWN_RADIUS = 0.65; // 音符生成位置
const APPROACH_TIME_MS = 800; // 音符從生成到判定線的時間

class ChartViewer {
  constructor() {
    this.canvas = document.getElementById('canvas');
    this.ctx = this.canvas.getContext('2d');
    this.canvas.width = CANVAS_SIZE;
    this.canvas.height = CANVAS_SIZE;
    
    this.chartData = null;
    this.audio = null;
    this.playing = false;
    this.speed = 1.0;
    this.currentTime = 0;
    this.animFrame = null;
    
    this.notes = [];
    
    this.init();
  }
  
  async init() {
    this.setupControls();
    await this.loadChart();
    await this.loadAudio();
    this.parseNotes();
    this.updateStatus(`已載入 ${this.notes.length} 個音符，準備完成`);
    this.render();
  }
  
  setupControls() {
    const playBtn = document.getElementById('playBtn');
    const resetBtn = document.getElementById('resetBtn');
    const progress = document.getElementById('progress');
    
    playBtn.onclick = () => this.togglePlay();
    resetBtn.onclick = () => this.reset();
    
    progress.onclick = (e) => {
      if (!this.audio) return;
      const rect = progress.getBoundingClientRect();
      const ratio = (e.clientX - rect.left) / rect.width;
      this.seek(ratio * this.audio.duration);
    };
    
    document.querySelectorAll('#speedControl button').forEach(btn => {
      btn.onclick = () => {
        document.querySelectorAll('#speedControl button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.setSpeed(parseFloat(btn.dataset.speed));
      };
    });
  }
  
  async loadChart() {
    try {
      const url = `https://assets2.lxns.net/maimai/chart/${CHART_ID}.txt`;
      const resp = await fetch(url);
      const text = await resp.text();
      this.chartData = text;
      this.updateStatus('譜面資料已載入');
    } catch (e) {
      this.updateStatus('載入譜面失敗：' + e.message);
      throw e;
    }
  }
  
  async loadAudio() {
    try {
      const url = `https://assets2.lxns.net/maimai/music/${MUSIC_ID}.mp3`;
      this.audio = new Audio();
      this.audio.crossOrigin = 'anonymous';
      this.audio.preload = 'auto';
      
      await new Promise((resolve, reject) => {
        this.audio.oncanplaythrough = resolve;
        this.audio.onerror = () => reject(new Error('音訊載入失敗'));
        this.audio.src = url;
      });
      
      this.audio.ontimeupdate = () => {
        if (this.playing) {
          this.currentTime = this.audio.currentTime * 1000;
          this.updateProgress();
        }
      };
      
      this.audio.onended = () => {
        this.playing = false;
        document.getElementById('playBtn').textContent = '▶ 播放';
      };
      
      this.updateStatus('音訊已載入');
    } catch (e) {
      this.updateStatus('載入音訊失敗：' + e.message);
      throw e;
    }
  }
  
  parseNotes() {
    const lines = this.chartData.split('\n');
    const msPerBeat = 60000 / BPM;
    
    let inNotes = false;
    let currentTime = 0;
    let currentSubdiv = 4; // 預設 4 分音符
    
    for (let line of lines) {
      line = line.trim().replace(/\r/g, '');
      
      // 找到音符區段開始
      if (line.startsWith('&inote_2=')) {
        inNotes = true;
        continue;
      }
      
      // 遇到下一個 & 開頭就結束
      if (inNotes && line.startsWith('&')) break;
      if (!inNotes || !line) continue;
      
      // 解析 subdivision 標記 {n}
      const subdivMatch = line.match(/^\{(\d+)\}/);
      if (subdivMatch) {
        currentSubdiv = parseInt(subdivMatch[1]);
        line = line.replace(/^\{\d+\}/, '');
      }
      
      // 解析 BPM 標記 (222)
      if (line.match(/^\(\d+\)/)) {
        continue; // 暫時跳過 BPM 變化
      }
      
      // 分割音符
      const parts = line.split(',');
      
      for (let i = 0; i < parts.length; i++) {
        const noteStr = parts[i].trim();
        if (!noteStr) continue;
        
        const timing = currentTime + (i / parts.length) * msPerBeat * (4 / currentSubdiv);
        
        // 解析每個音符位置
        this.parseNotesAtTiming(noteStr, timing);
      }
      
      // 每一行代表一個節拍組
      currentTime += msPerBeat * (4 / currentSubdiv);
    }
    
    // 按時間排序
    this.notes.sort((a, b) => a.time - b.time);
    console.log(`解析完成，共 ${this.notes.length} 個音符`);
    console.log('前 10 個音符:', this.notes.slice(0, 10));
  }
  
  parseNotesAtTiming(noteStr, timing) {
    // 移除空格
    noteStr = noteStr.replace(/\s/g, '');
    
    // 分割同時音符 /
    const simultaneous = noteStr.split('/');
    
    for (const note of simultaneous) {
      if (!note) continue;
      
      // 解析單個音符
      let pos = 0;
      let isBreak = false;
      let isHold = false;
      let isStar = false;
      
      // 提取位置數字 (1-8)
      const posMatch = note.match(/^(\d)/);
      if (!posMatch) continue;
      
      pos = parseInt(posMatch[1]);
      if (pos < 1 || pos > 8) continue;
      
      // 檢查修飾符
      isBreak = note.includes('b');
      isHold = note.includes('h');
      isStar = note.includes('x');
      
      this.notes.push({
        time: timing,
        position: pos,
        type: isBreak ? 'break' : isHold ? 'hold' : isStar ? 'star' : 'tap',
        angle: this.positionToAngle(pos)
      });
    }
  }
  
  positionToAngle(pos) {
    // maimai 位置：1=正上方，順時針，8 個位置
    // Canvas 角度：0=右側，逆時針
    // 需要轉換：pos 1 = -90°
    return ((pos - 1) * 45 - 90) * Math.PI / 180;
  }
  
  togglePlay() {
    if (!this.audio) return;
    
    if (this.playing) {
      this.audio.pause();
      this.playing = false;
      document.getElementById('playBtn').textContent = '▶ 播放';
      if (this.animFrame) cancelAnimationFrame(this.animFrame);
    } else {
      this.audio.play().catch(e => {
        this.updateStatus('播放失敗：' + e.message);
      });
      this.playing = true;
      document.getElementById('playBtn').textContent = '⏸ 暫停';
      this.animate();
    }
  }
  
  reset() {
    if (this.audio) {
      this.audio.pause();
      this.audio.currentTime = 0;
    }
    this.playing = false;
    this.currentTime = 0;
    document.getElementById('playBtn').textContent = '▶ 播放';
    this.updateProgress();
    this.render();
  }
  
  seek(time) {
    if (this.audio) {
      this.audio.currentTime = time;
      this.currentTime = time * 1000;
      this.render();
    }
  }
  
  setSpeed(speed) {
    this.speed = speed;
    if (this.audio) this.audio.playbackRate = speed;
    this.updateStatus(`播放速度：${speed}x`);
  }
  
  updateProgress() {
    if (!this.audio) return;
    const ratio = this.audio.currentTime / this.audio.duration;
    document.getElementById('progressBar').style.width = (ratio * 100) + '%';
  }
  
  updateStatus(text) {
    document.getElementById('status').textContent = text;
  }
  
  animate() {
    if (!this.playing) return;
    this.render();
    this.animFrame = requestAnimationFrame(() => this.animate());
  }
  
  render() {
    const ctx = this.ctx;
    const w = CANVAS_SIZE;
    const h = CANVAS_SIZE;
    const cx = w / 2;
    const cy = h / 2;
    const judgeRadius = w * JUDGE_LINE_RADIUS;
    const centerRadius = w * CENTER_RADIUS;
    
    // 背景
    ctx.fillStyle = '#0a0a0a';
    ctx.fillRect(0, 0, w, h);
    
    // 中央圓
    ctx.fillStyle = '#1a1a1a';
    ctx.beginPath();
    ctx.arc(cx, cy, centerRadius, 0, Math.PI * 2);
    ctx.fill();
    
    // 判定線
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.4)';
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.arc(cx, cy, judgeRadius, 0, Math.PI * 2);
    ctx.stroke();
    
    // 八個按鍵位置標記
    for (let i = 1; i <= 8; i++) {
      const angle = this.positionToAngle(i);
      const x = cx + Math.cos(angle) * judgeRadius;
      const y = cy + Math.sin(angle) * judgeRadius;
      
      ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
      ctx.beginPath();
      ctx.arc(x, y, 6, 0, Math.PI * 2);
      ctx.fill();
      
      // 位置編號
      ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
      ctx.font = '14px monospace';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const textX = cx + Math.cos(angle) * (judgeRadius + 20);
      const textY = cy + Math.sin(angle) * (judgeRadius + 20);
      ctx.fillText(i.toString(), textX, textY);
    }
    
    // 音符
    const currentMs = this.currentTime;
    
    for (const note of this.notes) {
      const timeDiff = note.time - currentMs;
      
      // 跳過已經過去太久的音符
      if (timeDiff < -300) continue;
      
      // 跳過還沒出現的音符
      if (timeDiff > APPROACH_TIME_MS) continue;
      
      // 計算音符位置：從外向內移動
      const progress = Math.max(0, Math.min(1, 1 - timeDiff / APPROACH_TIME_MS));
      const spawnRadius = w * NOTE_SPAWN_RADIUS;
      const noteRadius = spawnRadius - (spawnRadius - judgeRadius) * progress;
      
      const x = cx + Math.cos(note.angle) * noteRadius;
      const y = cy + Math.sin(note.angle) * noteRadius;
      
      // 音符已經過判定線，淡出
      const alpha = timeDiff < 0 ? Math.max(0, 1 + timeDiff / 300) : 1;
      
      // 音符外觀
      const size = 16;
      
      if (note.type === 'break') {
        ctx.fillStyle = `rgba(255, 200, 50, ${alpha})`;
        ctx.strokeStyle = `rgba(255, 150, 0, ${alpha})`;
      } else if (note.type === 'hold') {
        ctx.fillStyle = `rgba(255, 120, 255, ${alpha})`;
        ctx.strokeStyle = `rgba(200, 80, 200, ${alpha})`;
      } else if (note.type === 'star') {
        ctx.fillStyle = `rgba(255, 255, 100, ${alpha})`;
        ctx.strokeStyle = `rgba(255, 200, 50, ${alpha})`;
      } else {
        ctx.fillStyle = `rgba(255, 100, 200, ${alpha})`;
        ctx.strokeStyle = `rgba(255, 50, 150, ${alpha})`;
      }
      
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(x, y, size, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }
    
    // 時間顯示
    const totalSec = this.audio ? this.audio.duration : 0;
    const currentSec = this.currentTime / 1000;
    const timeText = `${this.formatTime(currentSec)} / ${this.formatTime(totalSec)}`;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
    ctx.font = '16px monospace';
    ctx.textAlign = 'center';
    ctx.fillText(timeText, cx, h - 30);
  }
  
  formatTime(sec) {
    const min = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${min}:${s.toString().padStart(2, '0')}`;
  }
}

window.addEventListener('DOMContentLoaded', () => {
  new ChartViewer();
});
