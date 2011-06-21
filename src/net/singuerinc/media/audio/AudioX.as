package net.singuerinc.media.audio {


	import flash.media.SoundTransform;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	/**
	 * @author nahuel.scotti / blog.singuerinc.net
	 */
	public class AudioX extends Audio implements IAudioX {

		protected var _positionInterval:uint;
		protected var _positionChanged:IAudioSignal;

		public function AudioX(id:String, sound:*) {
			super(id, sound);
			_delay = 0;
		}

		override public function set volume(value:Number):void {
			var vol:Number = Math.max(0, value);
			_fadeCurrentVolume = value;
			// TODO: Es posible optimizar esto?, sin tener que estar creando un nuevo soundTransform?
			// channel.soundTransform.volume = vol;
			channel.soundTransform = new SoundTransform(vol, pan);
			if (volumeChanged.numListeners > 0)
				volumeChanged.dispatch(this);
		}

		public function set pan(value:Number):void {
			// TODO: Es posible optimizar esto?, sin tener que estar creando un nuevo soundTransform?
			// channel.soundTransform.pan = value;
			channel.soundTransform = new SoundTransform(volume, value);
		}

		 public function get pan():Number {
		 	//FIXME: Hay un bug en flash player, si haces pan(-1), el value no es uno sino -0.9880999999999998
		 	//por lo tanto no se puede realizar un test
			 return _channel.soundTransform.pan;
		 }

		protected var _delayedPlay:uint;

		override public function pause():void {
			// FIXME: estos dos clear tal vez hay que hacerlos solo si esta en isPlaying() == true ?????
			clearTimeout(_positionInterval);
			clearTimeout(_delayedPlay);
			super.pause();
		}

		override public function play():void {

			if (delay && !isPlaying()) {
				_delayedPlay = setTimeout(super.play, delay);
				return;
			}

			super.play();
		}

		override public function resume():void {
			super.resume();
			if (isPlaying()) {
				if (positionChanged.numListeners > 0)
					_positionInterval = setInterval(onChangePosition, 100);
			}
		}

		protected function onChangePosition():void {
			trace('audio position:', position, 'of:', length);
			positionChanged.dispatch(this);
		}

		public function fade(time:uint = 1000, to:Number = 1, from:Number = -1):void {

			if (!isPlaying()) play();

			if (from != -1) {
				volume = _fadeFromVolume = from;
			} else {
				_fadeFromVolume = volume;
			}

			_fadeTime = time;
			_fadeToVolume = to;
			// _fadeCurrentVolume = from;

			clearInterval(_fadeInterval);
			_fadeInterval = setInterval(updateFadeVolume, 100);
			fadeStarted.dispatch(this);
		}

		public function get fadeStarted():IAudioSignal {
			return _fadeStarted ||= new AudioSignal();
		}

		public function get fadeCompleted():IAudioSignal {
			return _fadeCompleted ||= new AudioSignal();
		}

		protected var _fadeStarted:IAudioSignal;
		protected var _fadeCompleted:IAudioSignal;
		protected var _fadeInterval:uint;
		protected var _fadeToVolume:Number;
		protected var _fadeCurrentVolume:Number;
		protected var _fadeTime:uint;
		protected var _fadeFromVolume:Number;

		protected function updateFadeVolume():void {

			if (!isPlaying()) return;

			if (_fadeCurrentVolume < _fadeToVolume) {
				_fadeCurrentVolume += ((_fadeToVolume - _fadeFromVolume) / (_fadeTime / 100));
				volume = _fadeCurrentVolume;
			} else {
				volume = _fadeCurrentVolume;
				clearInterval(_fadeInterval);
				if (fadeCompleted.numListeners > 0) fadeCompleted.dispatch(this);
			}
		}

		protected var _delay:uint;

		public function set delay(value:uint):void {
			_delay = value;
		}

		public function get delay():uint {
			return _delay;
		}
		
		override public function get config():XML {
			return _config || <audio id={_id} volume={volume} loops={loops} delay={delay} pan={pan} />;
		}
		
		override protected function _parseConfig(audioConfig:XML):XML {

			var c:XML = super._parseConfig(audioConfig);

			// _fadeIn = c.@fadeIn;
			// _fadeOut = c.@fadeOut;
			_delay = c.@delay || _delay;
			pan = c.@pan || pan;

			return c;
		}

		public function get positionChanged():IAudioSignal {
			return _positionChanged ||= new AudioSignal();
		}

	}
}