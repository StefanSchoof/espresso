use funksteckdose::{error::Error, Pin, Value};
use gpio_cdev::{Chip, LineHandle, LineRequestFlags};

pub struct GpioPin {
    handle: LineHandle,
}

impl GpioPin {
    pub fn new(pin: u16) -> Result<GpioPin, gpio_cdev::Error> {
        let mut chip = Chip::new("/dev/gpiochip0")?;
        let line = chip.get_line(pin.into())?;
        let handle = line.request(LineRequestFlags::OUTPUT, 0, "funksteckdose")?;
        Ok(GpioPin { handle })
    }
}

impl Pin for GpioPin {
    fn set(&self, value: &Value) -> Result<(), Error> {
        match value {
            Value::High => self.handle.set_value(1),
            Value::Low => self.handle.set_value(0),
        };
        Ok(())
    }
}
