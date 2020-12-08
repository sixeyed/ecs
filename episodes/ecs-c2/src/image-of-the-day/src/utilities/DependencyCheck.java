import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.ProtocolException;
import java.net.URL;
import java.util.Properties;

public class DependencyCheck {

    public static void main(String[] args) throws FileNotFoundException, IOException, InterruptedException, ProtocolException { 
       
        System.out.println("** Sleeping for " + args[0] + "ms...");
        Long delayMs = Long.parseLong(args[0]);        
        Thread.sleep(delayMs);

        //read main app config:
        String sourcePath = System.getenv("CONFIG_TARGET_PATH");
        FileInputStream input = null;
		Properties properties = new Properties();
		try {
			input = new FileInputStream(sourcePath);
			properties.load(input); 
		} finally {
			input.close();
		}        

        URL url = new URL(properties.getProperty("apod.url") + properties.getProperty("apod.key"));
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        
        con.setRequestMethod("GET");
        con.setConnectTimeout(5000);
        con.setReadTimeout(5000);

        int status = con.getResponseCode();
        if (status == 200)
        {
            System.out.println("NASA API online");
            System.exit(0);
        }
        else
        {
            System.out.println("FAILED! NASA API returned status: " + status);
            System.exit(1);
        }
    }
}