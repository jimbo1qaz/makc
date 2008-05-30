using System;
using System.IO;

namespace D3SaveCompressor
{
	class D3SaveCompressorClass
	{
	
		static byte Dummy = 0x71; // 'q'
		static int Tail = 1000;
		static int Head = 2000;
		
	
		[STAThread]
		static void Main(string[] args)
		{
			// quit if args[0] is invalid filename
			bool ParamIsBad = false;
			if (args.Length < 1) ParamIsBad = true; else
			if (!File.Exists(args[0])) ParamIsBad = true;

			if (ParamIsBad)
				Console.WriteLine("No save file specified. Usage: D3SaveCompressor.exe <save filename>");
			else try
			{
				// read whole save into memory buffer
				FileStream fs_in = new FileStream(args[0], FileMode.Open);
				BinaryReader br_in = new BinaryReader(fs_in);
				byte [] buffer = br_in.ReadBytes((int)fs_in.Length);
				br_in.Close();
				fs_in.Close();
			
				// compress save by shortening all editor_usage text in it
				byte [] b_copy = new byte[buffer.Length];
				int b_length = 0, b_cutoff = buffer.Length - D3SaveCompressorClass.Tail;
				if (b_cutoff < D3SaveCompressorClass.Head)
					throw new Exception("This is rather small save, there's no need to compress it :P");

				int i=0; int cp = 1;
				for(i=0; i<b_cutoff; i++)
				{
					if (i % 100000 == 99999)
					{
						Console.WriteLine("100K checkpoint #" + cp.ToString()); cp ++;
					}
						
					if (buffer[i+2] + buffer[i+3] == 0)
					{
						int L1 = (int)buffer[i] + 256* (int)buffer[i+1];
						
						// L1 is supposedly chunk length; let's see if this is "editor_" stuff
						string chunk = "";
						for(int j=i+4; j<i+4 +20 /* 20 > 4 + "editor_".Length */; j++)
						{
							if(buffer[j] < 32) break;
							if(buffer[j] > 31) chunk += (char)buffer[j];
						}
						bool isEditorStuff = (chunk.IndexOf("editor_")==0);
						
						if (isEditorStuff)
						{
							// do compression: replace these two chunks with something shorter
							b_copy[b_length] = 1;
							b_copy[b_length + 1] = b_copy[b_length + 2] = b_copy[b_length + 3] = 0;
							b_length += 4;
							b_copy[b_length] = D3SaveCompressorClass.Dummy; b_length ++;
							
							i += +4+L1;
							
							L1 = (int)buffer[i] + 256* (int)buffer[i+1];
							i += +4+L1 -1;
							
							b_copy[b_length] = 1;
							b_copy[b_length + 1] = b_copy[b_length + 2] = b_copy[b_length + 3] = 0;
							b_length += 4;
							b_copy[b_length] = D3SaveCompressorClass.Dummy; b_length ++;
						}
						else
						{
							b_copy[b_length] = buffer[i]; b_length ++;
						}
					}
						
					else
					{
						b_copy[b_length] = buffer[i]; b_length ++;
					}
				}
				
				for(; i<buffer.Length; i++)
				{
					b_copy[b_length] = buffer[i]; b_length ++;
				}
				
				// write it down
				FileStream fs_out = new FileStream(args[0] + ".out", FileMode.Create);
				BinaryWriter bw_out = new BinaryWriter(fs_out);
				
				bw_out.Write(b_copy, 0, b_length);
				
				bw_out.Close();
				fs_out.Close();
				
			}
			catch (Exception oops)
			{
				Console.WriteLine("Oops. " + oops.ToString());
			}
		}
	}
}
