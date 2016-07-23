
Namespace wdw.game2d

Const DEVICE_KEYBOARD:Int = 0
Const DEVICE_JOYSTICK:Int = 1

Const JOYSTICK_XBOX:String = "Microsoft X-Box 360 pad"
Const JOYSTICK_PS3:String = "Sony PLAYSTATION(R)3 Controller"
Const JOYSTICK_PS4:String = "Sony Computer Entertainment Wireless Controller"


#Rem monkeydoc Input controller.

Manages control definitions and maps these to devices and their controls.

A control is added to the manager. A control maps to physical input. These can be keys, buttons, axes, hats

#End
Class InputManager

	#Rem monkeydoc Returns the instance of this InputManager.

	@return InputManager.

	#End
	Function GetInstance:InputManager()
		If Not _instance Then Return New InputManager
		Return _instance
	End Function


	#Rem monkeydoc @hidden
	#End
	Method New()
		DebugAssert( _instance = Null, "Unable to create another instance of singleton class: InputManager")
		_instance = Self

		_programming = False
		_activeDevice = DEVICE_KEYBOARD

		_keyboardControls = New StringMap<KeyboardControl>
		_joystickControls = New StringMap<Control>

		Self.DetectJoystick()
	End Method

	#Rem monkeydoc Deletes this manager.
	#End
	Method Destroy()
		_instance = Null
	End Method

	Property ActiveDevice:Int()
		Return _activeDevice
	Setter( value:Int )
		_activeDevice = value
	End

	#Rem monkeydoc Sets and returns the programming flag.

	@return True or False.

	#End
	Property Programming:Bool()
		Return _programming
	Setter( value:Bool )
		_programming = value

		' this forces the first control to be enabled for programming
		If _programming
			_previousProgramResult = True
		Else
			'reset prgramming tag on current conrol

			If _programmedControl
				_programmedControl.Programmed = False
			Endif
		Endif
	End

	Property ProgrammedControl:Control()
		Return _programmedControl
	End

	'retruns true if a control has been programmed
	'menu uses this to reset the flashing line timer.
	Method Update:Bool()
		If _programming
			If _activeDevice = DEVICE_KEYBOARD
				For Local control:= eachin _keyboardControls.Values

					' if previous control was programmed succesfully
					' then enable programming for this control
					If _previousProgramResult = True
						control.Programmed = True
						_programmedControl = control
					Endif
					_previousProgramResult = control.Update()
				Next
			Else
				For Local control:= eachin _joystickControls.Values

					' if previous control was programmed succesfully
					' then enable programming for this control
					If _previousProgramResult = True
						control.Programmed = True
						_programmedControl = control
					Endif
					_previousProgramResult = control.Update()
				Next
			Endif
			If _previousProgramResult = True Then _programming = False
		Endif
		Return _previousProgramResult

	End Method

' *** keyboard ***

	Property KeyboardControls:StringMap<KeyboardControl>()
		Return _keyboardControls
	End

	Method AddKeyboardControl:Void( name:string, key:Int)'Key)
		_keyboardControls.Set(name, New KeyboardControl(name, key) )
	End Method

	#Rem monkeydoc Returns true if the control with passed name is hit since the last update.

	@return Bool

	#End
	Method KeyHit:Bool( name:String )
		Return _keyboardControls.Get(name).Hit()
	End Method

	#Rem monkeydoc Returns true if the control with passed name is held down.

	@return Bool

	#End
	Method KeyDown:Bool( name:String )
		Return _keyboardControls.Get(name).Down()
	End Method

' ***** joypad *****

	#Rem monkeydoc @hidden

	Called when the menu is opened and when the game is started.
	It will check what the first joystick on the system is and create the appropriate mapping class.

	#End
	Method DetectJoystick:Void()

		'we only use the first pad on the system

		_joystickDevice = JoystickDevice.Open( 0 )
		If Not _joystickDevice Return

		Select _joystickDevice.Name
			Case JOYSTICK_XBOX
				_joystickDeviceMapping = New Xbox360
			Case JOYSTICK_PS3
				_joystickDeviceMapping = New Ps3
			Case JOYSTICK_PS4
				_joystickDeviceMapping = New Ps4
			Default
				_joystickDeviceMapping = New UnknownStick
		End Select

	End Method

	Method AddJoystickAxisControl:Void(name:String, buttonIndex:Int, targetValue:Float)
		_joystickControls.Set(name, New JoystickAxisControl( name, buttonIndex, targetValue ))
	End Method

	Method AddJoystickButtonControl:Void(name:String, buttonIndex:Int)
		_joystickControls.Set( name, New JoystickButtonControl( name, buttonIndex) )
	End Method


	Property JoystickControls:StringMap<Control>()
		Return _joystickControls
	End

	Property JoystickDevice:JoystickDevice()
		Return _joystickDevice
	End

	Property JoystickMapping:JoystickMapping()
		Return _joystickDeviceMapping
	End

	Property JoyStickLabel:String()
		Return _joystickDeviceMapping.Label
	End

	Method JoystickButtonHit:Bool( name:String )
		Local control:JoystickButtonControl = Cast<JoystickButtonControl>(_joystickControls.Get(name) )
		Return control.Hit()
	End Method

	Method JoystickButtonDown:Bool( name:String )
		Local control:JoystickButtonControl = Cast<JoystickButtonControl>(_joystickControls.Get(name) )
		Return control.Down()
	End Method

	Method JoystickAxisValue:Float( name:String )
		Local control:JoystickAxisControl = Cast<JoystickAxisControl>(_joystickControls.Get(name) )
		Return control.Value()
	End Method


	Method JoystickHatValue:JoystickHat(hatIndex:Int)
		If _joystickDeviceMapping.HatAmount-1 <= hatIndex
			Return _joystickDevice.GetHat(hatIndex)
		Endif
		Return JoystickHat.Centered
	End Method

' *** configuration

	Method ApplyConfiguration:Void(config:JsonObject)

		If config.Contains( "keyboardinput" )
			_keyboardControls.Clear()
			For local key:=Eachin config["keyboardinput"].ToArray()

				Local control:String[] = key.ToString().Split(":")
				AddKeyboardControl(control[0], Cast<Int>(control[1]))
			Next
		Endif

		If config.Contains( "joystickbuttons" )
			_joystickControls.Clear()
			For local key:=Eachin config["joystickbuttons"].ToArray()

				Local control:String[] = key.ToString().Split(":")
				AddJoystickButtonControl(control[0], Cast<Int>(control[1]))
			Next
		Endif

		'TODO: the added 0.0 is for target value later on
		' do not clear the map as then buttons will be gone :)
		If config.Contains( "joystickaxes" )
			For local key:=Eachin config["joystickaxes"].ToArray()

				Local control:String[] = key.ToString().Split(":")
				AddJoystickAxisControl(control[0], Cast<Int>(control[1]), 0.0)
			Next
		Endif
	End Method

	Private

	Field _programming:Bool
	Field _activeDevice:Int
	Field _previousProgramResult:Bool
	Field _programmedControl:Control

	' the plugged in joystick device
	Field _joystickDevice:JoystickDevice

	'mapping type. see joysticks.monkey2
	Field _joystickDeviceMapping:JoystickMapping

	Field _keyboardControls:StringMap<KeyboardControl>
	Field _joystickControls:StringMap<Control>

	Global _instance:InputManager

End Class


'--- helper functions ---------------------

Function AddJoystickButtonControl:Void( name:String, buttonIndex:Int )
	InputManager.GetInstance().AddJoystickButtonControl(name, buttonIndex)
End Function

Function AddJoystickAxisControl:Void( name:String, axisindex:Int, targetValue:Float = 0.0)
	InputManager.GetInstance().AddJoystickAxisControl(name, axisindex, targetValue)
End Function

Function JoystickButtonDown:Bool( name:String )
	Return InputManager.GetInstance().JoystickButtonDown(name)
End Function

Function JoystickButtonHit:Bool( name:String )
	Return InputManager.GetInstance().JoystickButtonHit(name)
End Function

Function JoystickAxisValue:Float( name:String )
	Return InputManager.GetInstance().JoystickAxisValue(name)
End Function

Function JoystickHatValue:JoystickHat( hatIndex:Int )
	Return InputManager.GetInstance().JoystickHatValue(hatIndex)
End Function

Function AddKeyboardControl:Void( name:String, key:Int)
	InputManager.GetInstance().AddKeyboardControl(name, key)
End Function

Function KeyboardControlDown:Bool( name:string )
	Return InputManager.GetInstance().KeyDown(name)
End Function

Function KeyboardControlHit:Bool( name:string )
	Return InputManager.GetInstance().KeyHit(name)
End Function

