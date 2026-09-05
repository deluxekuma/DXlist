const CHART_ID = 11377;
const MUSIC_ID = 1377;
const BPM = 222;
const CANVAS_SIZE = 800;
const JUDGE_LINE_RADIUS = 0.45;
const APPROACH_TIME_MS = 1000;

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
    this.startTime = 0;
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
    this.updateStatus('準備完成，點擊播放開始');
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
    // 簡化版 Simai 解析器：只處理基本 Tap、Break、Hold
    const lines = this.chartData.split('\n');
    let inNotes = false;
    let measureIndex = 0;
    const beatsPerMeasure = 4;
    const msPerBeat = 60000 / BPM;
    
    for (let line of lines) {
      line = line.trim();
      if (line.startsWith('&inote_')) {
        inNotes = true;
        continue;
      }
      if (inNotes && line.startsWith('&')) break;
      if (!inNotes || !line || line.startsWith('(')) continue;
      
      // 簡化：只抓單音符，不處理複雜語法
      const parts = line.split(',');
      for (let i = 0; i < parts.length; i++) {
        const note = parts[i].trim();
        if (!note || note === '{1}' || note === '{2}' || note === '{4}') continue;
        
        const timing = measureIndex * beatsPerMeasure * msPerBeat + 
                       (i / parts.length) * beatsPerMeasure * msPerBeat;
        
        // 解析位置 (1-8)
        let pos = 0;
        let isBreak = false;
        let isHold = false;
        
        if (/^\d/.test(note)) {
          pos = parseInt(note[0]);
          isBreak = note.includes('b');
          isHold = note.includes('h');
        }
        
        if (pos >= 1 && pos <= 8) {
          this.notes.push({
            time: timing,
            position: pos,
            type: isBreak ? 'break' : isHold ? 'hold' : 'tap',
            angle: ((pos - 1) * 45) * Math.PI / 180
          });
        }
      }
      
      if (line.includes(',')) measureIndex++;
    }
    
    console.log(`已解析 ${this.notes.length} 個音符`);
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
    const radius = w * JUDGE_LINE_RADIUS;
    
    // 背景
    ctx.fillStyle = '#0a0a0a';
    ctx.fillRect(0, 0, w, h);
    
    // 判定線
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.stroke();
    
    // 八個按鍵位置標記
    for (let i = 0; i < 8; i++) {
      const angle = (i * 45) * Math.PI / 180;
      const x = cx + Math.cos(angle - Math.PI / 2) * radius;
      const y = cy + Math.sin(angle - Math.PI / 2) * radius;
      
      ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
      ctx.beginPath();
      ctx.arc(x, y, 8, 0, Math.PI * 2);
      ctx.fill();
    }
    
    // 音符
    const currentMs = this.currentTime;
    
    for (const note of this.notes) {
      const timeDiff = note.time - currentMs;
      if (timeDiff < -200 || timeDiff > APPROACH_TIME_MS + 500) continue;
      
      const progress = 1 - Math.max(0, Math.min(1, timeDiff / APPROACH_TIME_MS));
      const noteRadius = radius * (1 - progress * 0.3);
      
      const x = cx + Math.cos(note.angle - Math.PI / 2) * noteRadius;
      const y = cy + Math.sin(note.angle - Math.PI / 2) * noteRadius;
      
      const alpha = timeDiff < 0 ? Math.max(0, 1 + timeDiff / 200) : 1;
      
      // 音符外觀
      if (note.type === 'break') {
        ctx.fillStyle = `rgba(255, 200, 0, ${alpha})`;
        ctx.strokeStyle = `rgba(255, 150, 0, ${alpha})`;
      } else if (note.type === 'hold') {
        ctx.fillStyle = `rgba(255, 100, 200, ${alpha})`;
        ctx.strokeStyle = `rgba(255, 50, 150, ${alpha})`;
      } else {
        ctx.fillStyle = `rgba(255, 100, 255, ${alpha})`;
        ctx.strokeStyle = `rgba(200, 50, 200, ${alpha})`;
      }
      
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(x, y, 18, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      
      // 時機指示環
      if (timeDiff > 0 && timeDiff < APPROACH_TIME_MS) {
        ctx.strokeStyle = `rgba(255, 255, 255, ${0.3 * alpha})`;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, y, 18 + (1 - progress) * 30, 0, Math.PI * 2);
        ctx.stroke();
      }
    }
    
    // 時間顯示
    const totalSec = this.audio ? this.audio.duration : 0;
    const currentSec = this.currentTime / 1000;
    const timeText = `${this.formatTime(currentSec)} / ${this.formatTime(totalSec)}`;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
    ctx.font = '14px monospace';
    ctx.textAlign = 'center';
    ctx.fillText(timeText, cx, cy + radius + 30);
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
