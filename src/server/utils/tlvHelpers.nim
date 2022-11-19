import tlv

proc tlvFromStringSeq*(arguments: seq[string]): tlv.Builder =
  result = initBuilder()  
  result.addInt32(cast[int32](len arguments))
  for argument in arguments: result.addString(argument)