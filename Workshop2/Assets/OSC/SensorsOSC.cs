using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SensorsOSC : MonoBehaviour
{

	public OSC osc;
	public int customEyeswebPort;
	public bool initialized;
	double ts, oldTs;

	public GameObject obj1;

	public void Start()
	{
		Init();
	}

	// Use this for initialization
	public void Init()
	{

		if (!osc.initialized) osc.Init();

		osc.SetAddressHandler("/sensors/respiration", GetRespirationFromOsc);
		osc.SetAddressHandler("/sensors/heartrate", GetHeartRateFromOsc);
		osc.SetAddressHandler("/sensors/peak", GetAccelerationFromOsc);

		//oldTs = Math.Round(System.DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1)).TotalSeconds * 1000, 2);

		initialized = true;
		Debug.Log("Osc initialized");

	}


	void GetRespirationFromOsc(OscMessage message)
	{
		float f1 = message.GetFloat(0);
		Debug.Log("respiration : " + f1);
	}

	void GetHeartRateFromOsc(OscMessage message)
	{
		float f1 = message.GetFloat(0);
		Debug.Log("heartrate : " + f1);
	}

	void GetAccelerationFromOsc(OscMessage message)
	{
		Vector3 acc = new Vector3(message.GetFloat(0), message.GetFloat(1), message.GetFloat(2));
		Debug.Log("peak : "+ acc);
	}

}
